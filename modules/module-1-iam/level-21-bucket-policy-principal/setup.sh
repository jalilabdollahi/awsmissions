#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://harborprint-proofs >/dev/null
seed="$(mktemp)"
trap 'rm -f "$seed"' EXIT
echo 'proof-sheet' > "$seed"
aws_local s3api put-object --bucket harborprint-proofs --key proofs/order-7731.pdf --body "$seed" >/dev/null

aws_local iam create-user --user-name proofreader >/dev/null
aws_local iam create-user --user-name proof-intern >/dev/null

aws_local s3api put-bucket-policy --bucket harborprint-proofs \
  --policy "file://$MISSION_DIR/workspace/bucket-policy.json"

echo "harborprint-proofs has a bucket policy and the reviewer is still locked out."
