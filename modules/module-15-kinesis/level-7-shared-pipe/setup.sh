#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

STREAM_ARN="arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/trade-ticks"
aws_local kinesis create-stream --stream-name trade-ticks --shard-count 2 >/dev/null
wait_for "stream trade-ticks" 20 aws_local kinesis describe-stream-summary --stream-name trade-ticks
for table in trade-ledger risk-scores; do
  aws_local dynamodb create-table --table-name "$table" \
    --attribute-definitions AttributeName=trade_id,AttributeType=S \
    --key-schema AttributeName=trade_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null
done

aws_local iam create-role --role-name trade-consumers-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:"dynamodb:UpdateItem",Resource:["arn:aws:dynamodb:us-east-1:\($acct):table/trade-ledger","arn:aws:dynamodb:us-east-1:\($acct):table/risk-scores"]},
  {Effect:"Allow",Action:["kinesis:GetRecords","kinesis:GetShardIterator","kinesis:DescribeStream","kinesis:ListShards","kinesis:SubscribeToShard","kinesis:DescribeStreamConsumer"],Resource:"*"}]}')"
aws_local iam put-role-policy --role-name trade-consumers-role --policy-name consume-trades --policy-document "$policy"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/ledger.zip" ledger.py && zip -q "$stage/scorer.zip" scorer.py)
aws_local lambda create-function --function-name ledger-writer \
  --runtime python3.12 --handler ledger.handler --timeout 15 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/trade-consumers-role" \
  --zip-file "fileb://$stage/ledger.zip" >/dev/null
aws_local lambda create-function --function-name risk-scorer \
  --runtime python3.12 --handler scorer.handler --timeout 15 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/trade-consumers-role" \
  --zip-file "fileb://$stage/scorer.zip" >/dev/null

for fn in ledger-writer risk-scorer; do
  aws_local lambda create-event-source-mapping --function-name "$fn" --event-source-arn "$STREAM_ARN" \
    --starting-position TRIM_HORIZON --batch-size 50 --maximum-batching-window-in-seconds 1 >/dev/null
done

echo "Both Lambdas read trade-ticks through the shared pipe."
