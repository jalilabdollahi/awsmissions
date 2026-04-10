#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
acl="$(aws_local s3api get-bucket-acl --bucket mission-bucket --output json 2>/dev/null || true)"
if [[ "$acl" != *'AllUsers'* ]]; then
  echo "mission-bucket ACL is no longer public-read."
  exit 0
fi
echo "mission-bucket ACL is still too open."
exit 1
