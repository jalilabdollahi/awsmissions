#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local cloudformation delete-stack --stack-name nightjar-archive >/dev/null 2>&1 || true

aws_local cloudformation create-stack --stack-name nightjar-archive \
  --template-body "file://$MISSION_DIR/workspace/template.yaml" >/dev/null
aws_local cloudformation wait stack-create-complete --stack-name nightjar-archive

# The records that must outlive the stack.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
for year in 2022 2023; do
  echo "ledger export $year" > "$tmp"
  aws_local s3api put-object --bucket nightjar-ledger-archive --key "exports/ledger-$year.csv" --body "$tmp" >/dev/null
done
for id in L-1001 L-1002 L-1003; do
  aws_local dynamodb put-item --table-name nightjar-ledger-index \
    --item "{\"entry\":{\"S\":\"$id\"},\"year\":{\"N\":\"2023\"}}" >/dev/null
done

echo "nightjar-archive is deployed and holds real records."
