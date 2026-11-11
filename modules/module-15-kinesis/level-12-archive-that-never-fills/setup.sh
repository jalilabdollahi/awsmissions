#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis create-stream --stream-name pageviews --shard-count 2 >/dev/null
wait_for "stream pageviews" 20 aws_local kinesis describe-stream-summary --stream-name pageviews
aws_local s3 mb s3://pinecrest-archive >/dev/null

aws_local iam create-role --role-name pageview-archive-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"firehose.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
policy="$(jq -cn --arg acct "$ACCOUNT_ID" '{Version:"2012-10-17",Statement:[
  {Effect:"Allow",Action:["s3:PutObject","s3:GetBucketLocation","s3:ListBucket"],Resource:["arn:aws:s3:::pinecrest-archive","arn:aws:s3:::pinecrest-archive/*"]},
  {Effect:"Allow",Action:["kinesis:DescribeStream","kinesis:GetShardIterator","kinesis:GetRecords","kinesis:ListShards"],Resource:"arn:aws:kinesis:us-east-1:\($acct):stream/pageviews"}]}')"
aws_local iam put-role-policy --role-name pageview-archive-role --policy-name archive-access --policy-document "$policy"

# Created months ago as a direct-put stream, so nothing ever flows into it.
aws_local firehose create-delivery-stream --delivery-stream-name pageview-archive \
  --delivery-stream-type DirectPut \
  --extended-s3-destination-configuration "file://$MISSION_DIR/workspace/archive.json" >/dev/null

for n in 1 2 3; do
  aws_local kinesis put-record --stream-name pageviews --partition-key "visitor-$n" \
    --data "$(printf '{"visitor":"v-%s","path":"/home"}\n' "$n" | base64)" >/dev/null
done

echo "pageviews carries traffic, pageview-archive exists, and the bucket stays empty."
