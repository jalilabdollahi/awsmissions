#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

out_file="$(mktemp)"
trap 'rm -f "$out_file"' EXIT

if ! aws_local lambda get-function --function-name invoice-digest >/dev/null 2>&1; then
  echo "The function invoice-digest no longer exists. Fix its role instead of recreating things."
  exit 1
fi

aws_local s3 rm s3://bluefin-digests/digest-2025-11-10.txt >/dev/null 2>&1 || true

# Real behaviour: run the function (first invoke can take ~10 seconds).
if ! aws_local lambda invoke --function-name invoice-digest "$out_file" >/dev/null 2>&1; then
  echo "The invoke call itself failed. Is the function still deployed?"
  exit 1
fi
payload="$(cat "$out_file")"

if printf '%s' "$payload" | grep -q 'errorMessage'; then
  msg="$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("errorMessage",""))')"
  echo "invoice-digest still fails inside Lambda: $msg"
  echo "The function runs with the permissions of its execution role, and nothing on that role allows this call yet."
  exit 1
fi

invoices="$(printf '%s' "$payload" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("invoices",-1))')"
if [ "$invoices" != "2" ]; then
  echo "The function ran but did not read the 2 invoices (it saw $invoices)."
  exit 1
fi
if ! aws_local s3api head-object --bucket bluefin-digests --key digest-2025-11-10.txt >/dev/null 2>&1; then
  echo "The function reported success but no digest file appeared in bluefin-digests."
  exit 1
fi
if printf '%s' "$payload" | grep -q '"hr_bucket_readable": true'; then
  echo "The function can read bluefin-hr-records. Grant access to the invoices and digests buckets only."
  exit 1
fi

echo "invoice-digest read 2 invoices, wrote its digest, and still cannot see the HR bucket."
