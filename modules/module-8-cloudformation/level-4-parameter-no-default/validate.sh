#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name fernwood-orders \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
if [ -z "$status" ]; then
  echo "No stack named fernwood-orders exists. Deploy the template under that name."
  exit 1
fi
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  *) echo "fernwood-orders is in $status, not CREATE_COMPLETE."; exit 1 ;;
esac

bucket="$(aws_local cloudformation describe-stacks --stack-name fernwood-orders \
  --query "Stacks[0].Outputs[?OutputKey=='OrdersBucket'].OutputValue" --output text)"
if [ -z "$bucket" ] || [ "$bucket" = "None" ]; then
  echo "The stack has no OrdersBucket output; did you deploy the whole template?"
  exit 1
fi
case "$bucket" in
  fernwood-orders-dub) ;;
  fernwood-orders-|fernwood-orders) echo "The bucket name ($bucket) has no branch code in it. Bucket names must carry the shop's code."; exit 1 ;;
  *) echo "The bucket is named $bucket, but this deployment is for branch dub."; exit 1 ;;
esac
if ! aws_local s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "The stack reports bucket $bucket but it is not there."
  exit 1
fi

echo "fernwood-orders is live for branch dub: bucket $bucket exists."
