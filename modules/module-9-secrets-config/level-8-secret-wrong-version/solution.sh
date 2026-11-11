#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=sable/cdn/signing-key
versions="$(aws_local secretsmanager list-secret-version-ids --secret-id "$SECRET" --output json)"
wrong="$(printf '%s' "$versions" | jq -r '.Versions[] | select(.VersionStages | index("AWSCURRENT")) | .VersionId')"
right="$(printf '%s' "$versions" | jq -r '.Versions[] | select(.VersionStages | index("AWSPREVIOUS")) | .VersionId')"

# Swap the label back; Secrets Manager relabels the other version AWSPREVIOUS.
aws_local secretsmanager update-secret-version-stage --secret-id "$SECRET" \
  --version-stage AWSCURRENT --move-to-version-id "$right" --remove-from-version-id "$wrong" >/dev/null
