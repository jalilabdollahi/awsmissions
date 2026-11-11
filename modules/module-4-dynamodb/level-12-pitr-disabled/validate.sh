#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tables="ledger-entries ledger-adjustments payouts-2026 ledger-scratch"
in_scope=""
for t in $tables; do
  arn="arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/$t"
  tag="$(aws_local dynamodb list-tags-of-resource --resource-arn "$arn" \
    --query 'Tags[?Key==`compliance`].Value' --output text 2>/dev/null || true)"
  if [ "$tag" = "sox" ]; then in_scope="$in_scope $t"; fi
  pitr="$(aws_local dynamodb describe-continuous-backups --table-name "$t" \
    --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' --output text 2>/dev/null || echo MISSING)"
  if [ "$t" = "ledger-scratch" ]; then
    if [ "$pitr" = "ENABLED" ]; then
      echo "ledger-scratch (compliance=none) has point-in-time recovery switched on. It is out of scope and costs money; leave it off."
      exit 1
    fi
    continue
  fi
  if [ "$tag" != "sox" ]; then
    echo "Tag compliance=sox was removed from $t. The fix is to protect the tables, not to change their classification."
    exit 1
  fi
  if [ "$pitr" != "ENABLED" ]; then
    echo "$t is tagged compliance=sox but point-in-time recovery is $pitr."
    exit 1
  fi
  # Behaviour: recovery must really work.
  target="restore-check-$t"
  if ! out="$(aws_local dynamodb restore-table-to-point-in-time --source-table-name "$t" \
      --target-table-name "$target" --use-latest-restorable-time 2>&1)"; then
    echo "Restoring $t to its latest restorable time failed: $(printf '%s' "$out" | tail -1)"
    exit 1
  fi
  rows="$(aws_local dynamodb scan --table-name "$target" --select COUNT --query Count --output text 2>/dev/null || echo 0)"
  aws_local dynamodb delete-table --table-name "$target" >/dev/null 2>&1 || true
  if [ "$rows" -lt 1 ]; then
    echo "The restored copy of $t came back empty."
    exit 1
  fi
done
echo "Every compliance=sox table can be restored to a point in time:$in_scope."
