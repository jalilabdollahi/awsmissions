#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'data' > "$seed"
for b in vantage-assets vantage-assets-eu vantage-renders vantage-payroll-exports vantage-legal-hold; do
  aws_local s3 mb "s3://$b" >/dev/null
  aws_local s3api put-object --bucket "$b" --key seed/file.txt --body "$seed" >/dev/null
done

aws_local iam create-user --user-name vantage-render >/dev/null
aws_local iam put-user-policy --user-name vantage-render --policy-name render-storage \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "vantage-render works fine, and can reach more than it should."
