#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://tidewater-claim-receipts >/dev/null
aws_local s3 mb s3://tidewater-claim-evidence >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/archiver.zip" archiver.py)

# The function still points at a role that the cleanup job deleted.
aws_local lambda create-function --function-name claim-receipt-archiver \
  --runtime python3.12 --handler archiver.archive \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/claim-archiver-role" \
  --environment 'Variables={RECEIPT_BUCKET=tidewater-claim-receipts}' \
  --zip-file "fileb://$stage/archiver.zip" >/dev/null

echo "claim-receipt-archiver points at role/claim-archiver-role, which no longer exists."
