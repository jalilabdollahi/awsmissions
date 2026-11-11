#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name card-swipes --shard-count 1 >/dev/null
wait_for "stream card-swipes" 20 aws_local kinesis describe-stream-summary --stream-name card-swipes

n=1
for cents in 1250 899 15000 320 4575 60; do
  id=$((1000 + n))
  aws_local kinesis put-record --stream-name card-swipes --partition-key "card-$id" \
    --data "$(printf '{"swipe_id":"sw-%s","cents":%s}' "$id" "$cents" | base64)" >/dev/null
  n=$((n + 1))
done

aws_local iam create-role --role-name swipe-audit-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name swipe-audit-role --policy-name read-swipes \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"kinesis:GetShardIterator\",\"kinesis:DescribeStreamSummary\",\"kinesis:ListShards\"],\"Resource\":\"arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/card-swipes\"},{\"Effect\":\"Allow\",\"Action\":\"kinesis:GetRecords\",\"Resource\":\"*\"}]}"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/audit.zip" audit.py)
aws_local lambda create-function --function-name swipe-audit \
  --runtime python3.12 --handler audit.handler --timeout 30 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/swipe-audit-role" \
  --zip-file "fileb://$stage/audit.zip" >/dev/null

echo "Six swipes sit in card-swipes; swipe-audit is deployed and reports nothing."
