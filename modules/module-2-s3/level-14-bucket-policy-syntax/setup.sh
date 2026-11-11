#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=quillhouse-partner-drop

aws_local s3 mb "s3://$B" >/dev/null
echo "print run 7731 - proofs" > "$work/proofs.txt"
echo "unreleased 2027 catalogue" > "$work/cat.txt"
aws_local s3 cp "$work/proofs.txt" "s3://$B/outbound/run-7731.txt" >/dev/null
aws_local s3 cp "$work/cat.txt" "s3://$B/internal/catalogue-2027.txt" >/dev/null

aws_local iam create-user --user-name partner-sync >/dev/null
aws_local iam create-user --user-name vendor-other >/dev/null

aws_local s3api put-bucket-policy --bucket "$B" --policy "file://$MISSION_DIR/workspace/bucket-policy.json"

echo "partner-sync gets AccessDenied for list, download and upload."
