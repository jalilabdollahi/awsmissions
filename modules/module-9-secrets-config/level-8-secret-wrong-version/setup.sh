#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=sable/cdn/signing-key
old_version="$(aws_local secretsmanager create-secret --name "$SECRET" \
  --description "CDN URL signing key" --secret-string 'sk-retired-7f31a9' \
  --query VersionId --output text)"
new_version="$(aws_local secretsmanager put-secret-value --secret-id "$SECRET" \
  --secret-string 'sk-fresh-c20d84' --query VersionId --output text)"

# Thursday's botched runbook step: AWSCURRENT is pulled back onto the retired version.
aws_local secretsmanager update-secret-version-stage --secret-id "$SECRET" \
  --version-stage AWSCURRENT --move-to-version-id "$old_version" \
  --remove-from-version-id "$new_version" >/dev/null

echo "The edge fleet is reading the retired signing key as the current version."
