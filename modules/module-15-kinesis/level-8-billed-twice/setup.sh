#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name usage-events --shard-count 1 >/dev/null
wait_for "stream usage-events" 20 aws_local kinesis describe-stream-summary --stream-name usage-events
aws_local dynamodb create-table --table-name invoice-lines \
  --attribute-definitions AttributeName=event_id,AttributeType=S \
  --key-schema AttributeName=event_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

# Three events already billed by the previous run; two more are waiting.
last_billed=""
for n in 1 2 3 4 5; do
  seq="$(aws_local kinesis put-record --stream-name usage-events --partition-key "sub-$n" \
    --data "$(printf '{"event_id":"ue-%s","mb":%s}' "$((2000 + n))" "$((n * 120))" | base64)" \
    --query SequenceNumber --output text)"
  if [ "$n" -le 3 ]; then
    last_billed="$seq"
    aws_local dynamodb put-item --table-name invoice-lines \
      --item "{\"event_id\":{\"S\":\"ue-$((2000 + n))\"},\"times_billed\":{\"N\":\"1\"}}" >/dev/null
  fi
done
aws_local ssm put-parameter --name /brightline/billing/checkpoint --type String --value "$last_billed" >/dev/null

aws_local iam create-role --role-name billing-resume-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:["kinesis:GetShardIterator","kinesis:ListShards","kinesis:DescribeStreamSummary"],Resource:"arn:aws:kinesis:us-east-1:\($acct):stream/usage-events"},
  {Effect:"Allow",Action:"kinesis:GetRecords",Resource:"*"},
  {Effect:"Allow",Action:["ssm:GetParameter","ssm:PutParameter"],Resource:"arn:aws:ssm:us-east-1:\($acct):parameter/brightline/billing/checkpoint"},
  {Effect:"Allow",Action:"dynamodb:UpdateItem",Resource:"arn:aws:dynamodb:us-east-1:\($acct):table/invoice-lines"}]}')"
aws_local iam put-role-policy --role-name billing-resume-role --policy-name resume-and-bill --policy-document "$policy"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/billing.zip" billing.py)
aws_local lambda create-function --function-name billing-resume \
  --runtime python3.12 --handler billing.handler --timeout 30 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/billing-resume-role" \
  --zip-file "fileb://$stage/billing.zip" >/dev/null

echo "Three events are billed, two are waiting, and the checkpoint points at the third."
