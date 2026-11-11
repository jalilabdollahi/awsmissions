#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

rm -f label_builder.zip
zip -q label_builder.zip label_builder.py
aws_local lambda create-function --function-name parcel-label-formatter \
  --runtime python3.12 --handler label_builder.build_label \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/parcel-label-role" \
  --zip-file fileb://label_builder.zip >/dev/null
aws_local lambda wait function-active-v2 --function-name parcel-label-formatter 2>/dev/null || true
