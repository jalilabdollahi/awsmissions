#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/orchard-reporter"
status="$(aws_local cloudformation describe-stacks --stack-name orchard-reporting \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  UPDATE_COMPLETE) ;;
  CREATE_COMPLETE) echo "orchard-reporting is still on release 1 (CREATE_COMPLETE). Release 2 has not been rolled out."; exit 1 ;;
  UPDATE_ROLLBACK_COMPLETE)
    reason="$(aws_local cloudformation describe-stack-events --stack-name orchard-reporting \
      --query "StackEvents[?ResourceStatus=='UPDATE_FAILED'].ResourceStatusReason | [0]" --output text)"
    echo "The last update was rolled back (UPDATE_ROLLBACK_COMPLETE). CloudFormation said: $reason"
    exit 1 ;;
  "") echo "The orchard-reporting stack does not exist."; exit 1 ;;
  *) echo "orchard-reporting is in $status."; exit 1 ;;
esac

probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "quarterly" > "$probe"

for bucket in orchard-reports orchard-archive; do
  set +e
  out="$(aws_as_role "$ROLE_ARN" report-bot "" s3api put-object --bucket "$bucket" \
    --key q3/report.csv --body "$probe" 2>&1)"
  rc=$?
  set -e
  if [ "$rc" -eq 98 ]; then
    echo "report-bot can no longer assume orchard-reporter; keep the trust policy as it was."
    exit 1
  fi
  if [ "$rc" -ne 0 ]; then
    echo "Upload to $bucket as orchard-reporter failed: $(printf '%s' "$out" | tail -1)"
    exit 1
  fi
done

if aws_as_role "$ROLE_ARN" report-bot "" s3api put-object --bucket orchard-payroll \
     --key leak.csv --body "$probe" >/dev/null 2>&1; then
  echo "The role can write to orchard-payroll. The release should grant exactly the two report buckets."
  exit 1
fi

echo "Release 2 is live: orchard-reporter can write to orchard-reports and orchard-archive, and nothing else."
