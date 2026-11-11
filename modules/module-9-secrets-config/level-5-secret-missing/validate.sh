#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=wyvern/matchmaker/db-credentials
if ! meta="$(aws_local secretsmanager describe-secret --secret-id "$SECRET" --output json 2>/dev/null)"; then
  echo "The secret $SECRET does not exist at all any more."
  exit 1
fi
if [ "$(printf '%s' "$meta" | jq -r '.DeletedDate // empty')" != "" ]; then
  echo "$SECRET is still scheduled for deletion; the matchmaker cannot read it."
  exit 1
fi

value="$(aws_local secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text 2>/dev/null || true)"
if [ -z "$value" ]; then
  echo "Reading $SECRET failed."
  exit 1
fi
if [ "$(printf '%s' "$value" | jq -r '.password // empty')" != "Quartz!Maple-4821" ] || \
   [ "$(printf '%s' "$value" | jq -r '.username // empty')" != "mm_service" ] || \
   [ "$(printf '%s' "$value" | jq -r '.host // empty')" != "mm-db.wyvern.internal" ]; then
  echo "The secret is readable but its contents are not the original credentials. The database still expects the old password."
  exit 1
fi

echo "$SECRET is readable again with its original credentials."
