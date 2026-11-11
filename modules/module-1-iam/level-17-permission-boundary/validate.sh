#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

file="$(mktemp)"
trap 'rm -f "$file"' EXIT
echo "rec $(date +%s)" > "$file"
intern() { aws_as_user skyhook-intern "$@"; }

boundary="$(aws_local iam get-user --user-name skyhook-intern --query 'User.PermissionsBoundary.PermissionsBoundaryArn' --output text 2>/dev/null || true)"
if [ -z "$boundary" ] || [ "$boundary" = "None" ]; then
  echo "skyhook-intern has no permissions boundary any more. The boundary is the platform team's safety net; adjust it, do not remove it."
  exit 1
fi

if ! out="$(intern s3api put-object --bucket skyhook-sandbox-recordings --key tests/run-002.bag --body "$file" 2>&1)"; then
  echo "skyhook-intern still cannot upload to the sandbox bucket: $(printf '%s' "$out" | tail -1)"
  echo "The identity policy allows it, so check the other thing that limits this user's permissions."
  exit 1
fi
if ! intern s3api get-object --bucket skyhook-sandbox-recordings --key tests/run-001.bag "$file" >/dev/null 2>&1; then
  echo "Uploading works but reading from the sandbox bucket broke. Keep the existing read permissions."
  exit 1
fi

if intern s3api put-object --bucket skyhook-prod-telemetry --key fleet/tamper.bin --body "$file" >/dev/null 2>&1; then
  echo "skyhook-intern can write to skyhook-prod-telemetry. The boundary now allows too much; keep it limited to the sandbox buckets."
  exit 1
fi
if intern s3api get-object --bucket skyhook-prod-telemetry --key fleet/2025-11-10.bin "$file" >/dev/null 2>&1; then
  echo "skyhook-intern can read production telemetry. The boundary must not open production."
  exit 1
fi
if intern s3api delete-object --bucket skyhook-sandbox-recordings --key tests/run-001.bag >/dev/null 2>&1; then
  echo "The intern can delete sandbox recordings. Only uploads were requested."
  exit 1
fi

echo "skyhook-intern uploads to the sandbox, is still fenced out of production, and keeps the boundary."
