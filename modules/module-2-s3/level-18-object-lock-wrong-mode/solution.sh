#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=fennel-ledger-archive

# Existing versions: GOVERNANCE can be upgraded to COMPLIANCE (never the other way round).
aws_local s3api list-object-versions --bucket "$B" --prefix ledger/ \
  --query 'Versions[].[Key,VersionId]' --output text | while read -r key vid; do
  aws_local s3api put-object-retention --bucket "$B" --key "$key" --version-id "$vid" \
    --retention '{"Mode":"COMPLIANCE","RetainUntilDate":"2028-01-01T00:00:00Z"}'
done

# New objects.
aws_local s3api put-object-lock-configuration --bucket "$B" --object-lock-configuration \
  '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"COMPLIANCE","Years":7}}}'
