#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/lumen-exporter"
status="$(aws_local cloudformation describe-stacks --stack-name lumen-export \
  --query 'Stacks[0].StackStatus' --output text 2>/dev/null || true)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) ;;
  "") echo "The lumen-export stack is gone; the role should be managed by it."; exit 1 ;;
  *) echo "lumen-export is in $status; get it back to a healthy state."; exit 1 ;;
esac

probe="$(mktemp)"
trap 'rm -f "$probe"' EXIT
echo "result-set" > "$probe"

set +e
out="$(aws_as_role "$ROLE_ARN" export-runner "" s3api put-object \
  --bucket lumen-lab-exports --key nightly/results.csv --body "$probe" 2>&1)"
rc=$?
set -e
if [ "$rc" -eq 98 ]; then
  echo "export-runner still cannot assume lumen-exporter. Look at who the role's trust policy lets in."
  exit 1
fi
if [ "$rc" -ne 0 ]; then
  echo "export-runner assumed the role, but the upload to lumen-lab-exports failed: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

if aws_as_role "$ROLE_ARN" intern-sandbox "" sts get-caller-identity >/dev/null 2>&1; then
  echo "Too open: intern-sandbox can also assume lumen-exporter. Trust only export-runner."
  exit 1
fi
if aws_as_role "$ROLE_ARN" export-runner "" s3api put-object \
     --bucket lumen-hr-records --key leak.csv --body "$probe" >/dev/null 2>&1; then
  echo "Too open: the role can now write to lumen-hr-records. Keep its permissions on the export bucket only."
  exit 1
fi

echo "export-runner can assume lumen-exporter and upload results; nobody else can wear the role."
