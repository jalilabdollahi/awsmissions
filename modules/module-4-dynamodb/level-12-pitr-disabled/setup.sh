#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

mk() {
  aws_local dynamodb create-table --table-name "$1" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --tags "Key=compliance,Value=$2" "Key=owner,Value=finance-platform" >/dev/null
  aws_local dynamodb put-item --table-name "$1" --item "{\"id\":{\"S\":\"row-1\"},\"amount\":{\"N\":\"4200\"}}"
}
mk ledger-entries sox
mk ledger-adjustments sox
mk payouts-2026 sox
mk ledger-scratch none

# Only the first one was protected.
aws_local dynamodb update-continuous-backups --table-name ledger-entries \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true >/dev/null

echo "Four ledger tables exist. Only one has point-in-time recovery."
