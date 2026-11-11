#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "quarterly feed" > "$work/feed.csv"

for b in ridgeline-open-data ridgeline-partner-feeds ridgeline-internal-reports ridgeline-build-cache; do
  aws_local s3 mb "s3://$b" >/dev/null
done
aws_local s3 cp "$work/feed.csv" s3://ridgeline-partner-feeds/q3/feed.csv >/dev/null
aws_local s3 cp "$work/feed.csv" s3://ridgeline-open-data/census/feed.csv >/dev/null

# The runaway script: it was meant for ridgeline-open-data only.
for b in ridgeline-open-data ridgeline-partner-feeds ridgeline-internal-reports; do
  aws_local s3api put-bucket-request-payment --bucket "$b" \
    --request-payment-configuration Payer=Requester
done

aws_local iam create-user --user-name feed-consumer >/dev/null
aws_local iam put-user-policy --user-name feed-consumer --policy-name read-feeds \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": ["s3:GetObject"], "Resource": "arn:aws:s3:::ridgeline-partner-feeds/*"}
    ]
  }'

echo "Requester Pays is on for three Ridgeline buckets."
