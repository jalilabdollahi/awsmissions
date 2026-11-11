#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://swiftcab-lake >/dev/null

aws_local iam create-role --role-name ride-shaper-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":["lambda.amazonaws.com","firehose.amazonaws.com"]},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:["s3:PutObject","s3:GetBucketLocation","s3:ListBucket"],Resource:["arn:aws:s3:::swiftcab-lake","arn:aws:s3:::swiftcab-lake/*"]},
  {Effect:"Allow",Action:["lambda:InvokeFunction","lambda:GetFunctionConfiguration"],Resource:"arn:aws:lambda:us-east-1:\($acct):function:ride-event-shaper"}]}')"
aws_local iam put-role-policy --role-name ride-shaper-role --policy-name lake-and-shaper --policy-document "$policy"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/shaper.zip" shaper.py)
aws_local lambda create-function --function-name ride-event-shaper \
  --runtime python3.12 --handler shaper.handler --timeout 20 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/ride-shaper-role" \
  --zip-file "fileb://$stage/shaper.zip" >/dev/null

config="$(jq -cn --arg acct "$ACCOUNT_ID" '{
  RoleARN: "arn:aws:iam::\($acct):role/ride-shaper-role",
  BucketARN: "arn:aws:s3:::swiftcab-lake",
  Prefix: "rides/",
  ErrorOutputPrefix: "ride-rejects/!{firehose:error-output-type}/",
  BufferingHints: {SizeInMBs: 1, IntervalInSeconds: 5},
  ProcessingConfiguration: {Enabled: true, Processors: [{Type: "Lambda",
    Parameters: [{ParameterName: "LambdaArn", ParameterValue: "arn:aws:lambda:us-east-1:\($acct):function:ride-event-shaper"}]}]}
}')"
aws_local firehose create-delivery-stream --delivery-stream-name ride-events-to-lake \
  --delivery-stream-type DirectPut --extended-s3-destination-configuration "$config" >/dev/null

echo "ride-events-to-lake runs every event through ride-event-shaper, and the rewrite broke the contract."
