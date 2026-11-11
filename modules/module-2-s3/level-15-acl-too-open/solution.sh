#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=sunrise-photos

# Stop ACLs from granting public access again.
aws_local s3api put-public-access-block --bucket "$B" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Clean the existing grants.
aws_local s3api put-bucket-acl --bucket "$B" --acl private
for key in $(aws_local s3api list-objects-v2 --bucket "$B" --query 'Contents[].Key' --output text); do
  aws_local s3api put-object-acl --bucket "$B" --key "$key" --acl private
done
