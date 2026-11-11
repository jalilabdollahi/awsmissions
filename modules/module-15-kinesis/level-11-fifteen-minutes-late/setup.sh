#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://aldermoor-fraud-landing >/dev/null

aws_local iam create-role --role-name fraud-firehose-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"firehose.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name fraud-firehose-role --policy-name land-signals \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:PutObject\",\"s3:GetBucketLocation\",\"s3:ListBucket\"],\"Resource\":[\"arn:aws:s3:::aldermoor-fraud-landing\",\"arn:aws:s3:::aldermoor-fraud-landing/*\"]}]}"

hints="$(jq -c '.BufferingHints' "$MISSION_DIR/workspace/buffering.json")"
config="$(jq -cn --arg role "arn:aws:iam::${ACCOUNT_ID}:role/fraud-firehose-role" --argjson hints "$hints" '{
  RoleARN: $role,
  BucketARN: "arn:aws:s3:::aldermoor-fraud-landing",
  Prefix: "signals/",
  ErrorOutputPrefix: "signal-errors/!{firehose:error-output-type}/",
  BufferingHints: $hints,
  CompressionFormat: "UNCOMPRESSED"
}')"
aws_local firehose create-delivery-stream --delivery-stream-name fraud-signals-to-s3 \
  --delivery-stream-type DirectPut --extended-s3-destination-configuration "$config" >/dev/null

echo "fraud-signals-to-s3 accepts signals, and holds on to them for a long time."
