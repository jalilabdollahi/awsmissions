#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=sunrise-photos
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

public_grants() { # prints the group URIs that are public in an ACL JSON on stdin
  python3 -c '
import json, sys
acl = json.load(sys.stdin)
for g in acl.get("Grants", []):
    uri = g.get("Grantee", {}).get("URI", "")
    if uri.endswith("/AllUsers") or uri.endswith("/AuthenticatedUsers"):
        print(uri.rsplit("/", 1)[-1], g.get("Permission"))'
}

bucket_pub="$(aws_local s3api get-bucket-acl --bucket "$B" --output json | public_grants)"
if [ -n "$bucket_pub" ]; then
  echo "The bucket ACL still grants access to a public group: $bucket_pub"
  exit 1
fi

keys="$(aws_local s3api list-objects-v2 --bucket "$B" --query 'Contents[].Key' --output text)"
count=0
for key in $keys; do
  count=$((count + 1))
  pub="$(aws_local s3api get-object-acl --bucket "$B" --key "$key" --output json | public_grants)"
  if [ -n "$pub" ]; then
    echo "The object $key still has a public ACL grant: $pub"
    exit 1
  fi
done
if [ "$count" -lt 3 ]; then
  echo "Objects were deleted. The photos had to be kept; only their ACLs should change."
  exit 1
fi

# The fix must be durable: either ACLs are disabled, or public ACLs are blocked.
owner="$(aws_local s3api get-bucket-ownership-controls --bucket "$B" \
  --query 'OwnershipControls.Rules[0].ObjectOwnership' --output text 2>/dev/null || echo none)"
pab="$(aws_local s3api get-public-access-block --bucket "$B" \
  --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls]' --output text 2>/dev/null || echo "False False")"
if [ "$owner" != "BucketOwnerEnforced" ] && [ "$pab" != "True	True" ]; then
  echo "Nothing prevents the next uploader script from making objects public again. Disable ACLs or block public ACLs."
  exit 1
fi

# Legitimate access must survive.
if ! aws_as_user renderer-app s3api get-object --bucket "$B" --key galleries/smith-wedding/001.jpg "$work/o.jpg" >/dev/null 2>&1; then
  echo "renderer-app can no longer read the gallery photos."
  exit 1
fi
echo "No public ACLs remain, ACL exposure is blocked, and the web app still renders the gallery."
