#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=cinder/warehouse/login
current="$(aws_local secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text 2>/dev/null || true)"
if [ -z "$current" ]; then
  echo "Could not read $SECRET."
  exit 1
fi
if ! printf '%s' "$current" | jq -e . >/dev/null 2>&1; then
  echo "The secret value is not valid JSON."
  exit 1
fi

field() { printf '%s' "$current" | jq -r --arg k "$1" '.[$k] // empty'; }

# The dashboard's view.
if [ -z "$(field user)" ] || [ -z "$(field pass)" ]; then
  echo "The dashboard still cannot find its fields: it reads \"user\" and \"pass\"."
  exit 1
fi
if [ "$(field user)" != "wh_loader" ] || [ "$(field pass)" != "Birch*Anvil-7733" ]; then
  echo "user/pass exist but do not hold the real warehouse credentials."
  exit 1
fi
# The billing job's view (it must not break).
if [ "$(field username)" != "wh_loader" ] || [ "$(field password)" != "Birch*Anvil-7733" ]; then
  echo "The billing job's fields (username/password) were changed or removed. It must keep working."
  exit 1
fi
if [ "$(field host)" != "wh.cinder.internal" ] || [ "$(field port)" != "5432" ]; then
  echo "host and port must stay in the secret."
  exit 1
fi

# History: a new version on top of the old one, not a delete-and-recreate.
prev="$(aws_local secretsmanager get-secret-value --secret-id "$SECRET" --version-stage AWSPREVIOUS \
  --query SecretString --output text 2>/dev/null || true)"
if [ -z "$prev" ]; then
  echo "There is no AWSPREVIOUS version. Update the existing secret with a new version instead of recreating it."
  exit 1
fi
if [ "$(printf '%s' "$prev" | jq -r '.password // empty')" != "Birch*Anvil-7733" ]; then
  echo "The previous version is not the original one."
  exit 1
fi

echo "Both consumers can read their fields from cinder/warehouse/login, and the old version is kept as AWSPREVIOUS."
