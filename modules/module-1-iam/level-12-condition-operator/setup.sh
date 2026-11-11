#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://ashgrove-case-files >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'privileged' > "$seed"
for key in matters/2025/smith-v-jones/complaint.txt matters/2025/okafor-estate/will.txt matters/2024/archive/closed.txt; do
  aws_local s3api put-object --bucket ashgrove-case-files --key "$key" --body "$seed" >/dev/null
done

aws_local iam create-user --user-name ashgrove-clerk >/dev/null
aws_local iam put-user-policy --user-name ashgrove-clerk --policy-name clerk-browse \
  --policy-document "file://$MISSION_DIR/workspace/policy.json"

echo "ashgrove-clerk has a prefix-restricted policy that matches nothing."
