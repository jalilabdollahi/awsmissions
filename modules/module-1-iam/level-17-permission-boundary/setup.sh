#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://skyhook-sandbox-recordings >/dev/null
aws_local s3 mb s3://skyhook-prod-telemetry >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'rec' > "$seed"
aws_local s3api put-object --bucket skyhook-sandbox-recordings --key tests/run-001.bag --body "$seed" >/dev/null
aws_local s3api put-object --bucket skyhook-prod-telemetry --key fleet/2025-11-10.bin --body "$seed" >/dev/null

boundary_arn="$(aws_local iam create-policy --policy-name intern-boundary \
  --policy-document "file://$MISSION_DIR/workspace/boundary.json" --query Policy.Arn --output text)"

aws_local iam create-user --user-name skyhook-intern >/dev/null
aws_local iam put-user-policy --user-name skyhook-intern --policy-name s3-for-the-team \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
aws_local iam put-user-permissions-boundary --user-name skyhook-intern --permissions-boundary "$boundary_arn"

echo "skyhook-intern has s3:* on paper and cannot upload a thing."
