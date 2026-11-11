#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# A delivery stream's type cannot be changed: replace it, under the same name.
aws_local firehose delete-delivery-stream --delivery-stream-name pageview-archive >/dev/null
wait_for "old delivery stream gone" 60 bash -c "! aws --endpoint-url=$AWS_ENDPOINT_URL firehose describe-delivery-stream --delivery-stream-name pageview-archive >/dev/null 2>&1"

aws_local firehose create-delivery-stream --delivery-stream-name pageview-archive \
  --delivery-stream-type KinesisStreamAsSource \
  --kinesis-stream-source-configuration "KinesisStreamARN=arn:aws:kinesis:us-east-1:${ACCOUNT_ID}:stream/pageviews,RoleARN=arn:aws:iam::${ACCOUNT_ID}:role/pageview-archive-role" \
  --extended-s3-destination-configuration file://archive.json >/dev/null
