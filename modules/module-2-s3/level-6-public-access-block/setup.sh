#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://lumen-brand-assets >/dev/null
echo "LUMEN logo v3 (svg)" > "$work/logo.txt"
echo "DRAFT - agency contract, not for release" > "$work/draft.txt"
aws_local s3 cp "$work/logo.txt" s3://lumen-brand-assets/public/logo.txt >/dev/null
aws_local s3 cp "$work/draft.txt" s3://lumen-brand-assets/private/agency-contract-draft.txt >/dev/null

# Last quarter's hardening.
aws_local s3api put-public-access-block --bucket lumen-brand-assets \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# An anonymous-style visitor: a user with no permissions of its own.
aws_local iam create-user --user-name press-visitor >/dev/null

echo "The public-read policy is being rejected with Access Denied."
