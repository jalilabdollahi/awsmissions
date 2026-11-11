#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name order-events --shard-count 4 >/dev/null
wait_for "stream order-events" 20 aws_local kinesis describe-stream-summary --stream-name order-events

aws_local iam create-role --role-name order-publisher-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name order-publisher-role --policy-name publish-orders \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"kinesis:PutRecord\",\"kinesis:PutRecords\"],\"Resource\":\"arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/order-events\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/publisher.zip" publisher.py)
aws_local lambda create-function --function-name order-publisher \
  --runtime python3.12 --handler publisher.handler --timeout 20 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/order-publisher-role" \
  --zip-file "fileb://$stage/publisher.zip" >/dev/null

echo "order-events has 4 shards; order-publisher is live and every event goes to the same place."
