#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://harborview-datalake >/dev/null

aws_local iam create-role --role-name clickstream-firehose-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"firehose.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name clickstream-firehose-role --policy-name write-lake \
  --policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:PutObject\",\"s3:GetBucketLocation\",\"s3:ListBucket\"],\"Resource\":[\"arn:aws:s3:::harborview-datalake\",\"arn:aws:s3:::harborview-datalake/*\"]}]}"

# The rebuilt delivery stream: wrong bucket name and a prefix the Athena table does not read.
aws_local firehose create-delivery-stream --delivery-stream-name clickstream-to-lake \
  --delivery-stream-type DirectPut \
  --extended-s3-destination-configuration "file://$MISSION_DIR/workspace/destination.json" >/dev/null

# Last week's traffic: a record goes in, and lands somewhere unexpected.
aws_local firehose put-record --delivery-stream-name clickstream-to-lake \
  --record "Data=$(printf '{"page":"/pricing","visitor":"v-91"}\n' | base64)" >/dev/null
wait_for "first delivery" 30 bash -c "aws --endpoint-url=$AWS_ENDPOINT_URL s3 ls | grep -q harborview-data-lake" || true

echo "clickstream-to-lake is delivering, just not where the data engineers are looking."
