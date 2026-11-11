#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

status="$(aws_local cloudformation describe-stacks --stack-name ledgerline-auditor \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "ledgerline-auditor does not exist. Deploy the auditor template under that name."; exit 1 ;;
  ROLLBACK_COMPLETE|CREATE_FAILED)
    reason="$(aws_local cloudformation describe-stack-events --stack-name ledgerline-auditor \
      --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].ResourceStatusReason | [0]" --output text)"
    echo "ledgerline-auditor is in $status: $reason"
    echo "That stack cannot be updated; remove it and deploy the corrected template."
    exit 1 ;;
  *) echo "ledgerline-auditor is in $status."; exit 1 ;;
esac

topic="$(aws_local ssm get-parameter --name /ledgerline/audit/topic-arn --query Parameter.Value --output text 2>/dev/null || true)"
bucket="$(aws_local ssm get-parameter --name /ledgerline/audit/bucket --query Parameter.Value --output text 2>/dev/null || true)"

if [ "$topic" != "arn:aws:sns:us-east-1:${ACCOUNT_ID}:ledgerline-prod-audit" ]; then
  case "$topic" in
    *staging*) echo "/ledgerline/audit/topic-arn points at the STAGING topic ($topic). Compliance needs production." ;;
    *) echo "/ledgerline/audit/topic-arn holds '${topic:-nothing}', not the production audit topic ARN." ;;
  esac
  exit 1
fi
if [ "$bucket" != "ledgerline-prod-audit-log" ]; then
  case "$bucket" in
    *staging*) echo "/ledgerline/audit/bucket points at the STAGING bucket ($bucket). Compliance needs production." ;;
    *) echo "/ledgerline/audit/bucket holds '${bucket:-nothing}', not the production audit bucket." ;;
  esac
  exit 1
fi

echo "ledgerline-auditor records the production audit topic and bucket, imported from the platform stack."
