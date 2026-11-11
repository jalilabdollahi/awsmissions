#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for t in $(aws_local dynamodb list-tables --query 'TableNames[]' --output text); do
  tag="$(aws_local dynamodb list-tags-of-resource \
    --resource-arn "arn:aws:dynamodb:us-east-1:${ACCOUNT_ID}:table/$t" \
    --query 'Tags[?Key==`compliance`].Value' --output text)"
  if [ "$tag" = "sox" ]; then
    aws_local dynamodb update-continuous-backups --table-name "$t" \
      --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true >/dev/null
  fi
done
