#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=datavault-exports
aws_local s3 mb "s3://$B" >/dev/null

# Three uploads that were started and never finished.
for key in exports/2026-10-14/warehouse.parquet exports/2026-10-15/warehouse.parquet tmp/staging-dump.bin; do
  aws_local s3api create-multipart-upload --bucket "$B" --key "$key" >/dev/null
done

aws_local s3api put-bucket-lifecycle-configuration --bucket "$B" \
  --lifecycle-configuration "file://$MISSION_DIR/workspace/lifecycle.json"

echo "Abandoned multipart uploads are sitting in datavault-exports."
