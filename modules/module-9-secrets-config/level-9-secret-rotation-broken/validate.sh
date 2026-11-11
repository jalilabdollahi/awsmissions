#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=pelican/orders-db/password
meta="$(aws_local secretsmanager describe-secret --secret-id "$SECRET" --output json 2>/dev/null || true)"
if [ -z "$meta" ]; then
  echo "The secret $SECRET does not exist."
  exit 1
fi

enabled="$(printf '%s' "$meta" | jq -r '.RotationEnabled // false')"
target="$(printf '%s' "$meta" | jq -r '.RotationLambdaARN // empty')"
days="$(printf '%s' "$meta" | jq -r '.RotationRules.AutomaticallyAfterDays // empty')"

if [ "$enabled" != "true" ] || [ -z "$target" ]; then
  echo "Rotation is not enabled on $SECRET."
  exit 1
fi

fn_name="${target##*:}"
if ! aws_local lambda get-function --function-name "$fn_name" >/dev/null 2>&1; then
  echo "Rotation is configured, but its function ($fn_name) does not exist, so no rotation can ever run."
  exit 1
fi
if [ "$fn_name" != "pelican-rotate-orders-db" ]; then
  echo "Rotation uses the function $fn_name, which is not the rotator deployed for the orders database."
  exit 1
fi
if [ -z "$days" ] || [ "$days" -gt 30 ]; then
  echo "Rotation interval is ${days:-unset} days; policy requires at least every 30 days."
  exit 1
fi

# The secret itself must not have been replaced along the way.
if ! aws_local secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text 2>/dev/null | jq -e '.username == "orders_admin"' >/dev/null; then
  echo "The secret's contents no longer look like the orders database login."
  exit 1
fi

echo "$SECRET rotates through $fn_name every $days days."
