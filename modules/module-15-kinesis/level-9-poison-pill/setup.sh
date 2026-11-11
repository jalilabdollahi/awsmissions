#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name vitals --shard-count 1 >/dev/null
wait_for "stream vitals" 20 aws_local kinesis describe-stream-summary --stream-name vitals
aws_local sqs create-queue --queue-name vitals-dead-letters >/dev/null
aws_local dynamodb create-table --table-name vitals-processed \
  --attribute-definitions AttributeName=reading_id,AttributeType=S \
  --key-schema AttributeName=reading_id,KeyType=HASH --billing-mode PAY_PER_REQUEST >/dev/null

aws_local iam create-role --role-name vitals-alerter-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:"dynamodb:PutItem",Resource:"arn:aws:dynamodb:us-east-1:\($acct):table/vitals-processed"},
  {Effect:"Allow",Action:["kinesis:GetRecords","kinesis:GetShardIterator","kinesis:DescribeStream","kinesis:ListShards"],Resource:"*"},
  {Effect:"Allow",Action:"sqs:SendMessage",Resource:"arn:aws:sqs:us-east-1:\($acct):vitals-dead-letters"}]}')"
aws_local iam put-role-policy --role-name vitals-alerter-role --policy-name alert-pipeline --policy-document "$policy"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/alerter.zip" alerter.py)
aws_local lambda create-function --function-name vitals-alerter \
  --runtime python3.12 --handler alerter.handler --timeout 15 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/vitals-alerter-role" \
  --zip-file "fileb://$stage/alerter.zip" >/dev/null

# Two good readings, the broken one, then two more good ones.
for body in '{"reading_id":"vr-1","spo2":97}' '{"reading_id":"vr-2","spo2":95}' '{"reading_id":"vr-3-BROKEN","spo2":' \
            '{"reading_id":"vr-4","spo2":98}' '{"reading_id":"vr-5","spo2":96}'; do
  aws_local kinesis put-record --stream-name vitals --partition-key bed-12 --data "$(printf '%s' "$body" | base64)" >/dev/null
done

aws_local lambda create-event-source-mapping --function-name vitals-alerter \
  --event-source-arn "arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/vitals" \
  --starting-position TRIM_HORIZON --batch-size 10 --maximum-batching-window-in-seconds 1 >/dev/null

echo "vitals-alerter is wired to the vitals stream and is choking on reading vr-3."
