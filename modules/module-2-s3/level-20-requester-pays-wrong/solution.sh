#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for b in $(aws_local s3api list-buckets --query 'Buckets[?starts_with(Name, `ridgeline-`)].Name' --output text); do
  [ "$b" = "ridgeline-open-data" ] && continue
  if [ "$(aws_local s3api get-bucket-request-payment --bucket "$b" --query Payer --output text)" = "Requester" ]; then
    aws_local s3api put-bucket-request-payment --bucket "$b" --request-payment-configuration Payer=BucketOwner
  fi
done
