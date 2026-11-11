#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

probe="$(mktemp)"
dest="$(mktemp)"
trap 'rm -f "$probe" "$dest"' EXIT
echo "probe" > "$probe"

if ! aws_local iam get-user --user-name ledgerlens-report >/dev/null 2>&1; then
  echo "The user ledgerlens-report is gone. The dashboard needs it to keep existing."
  exit 1
fi

# The dashboard must still be able to browse the bucket (that part was never broken).
if ! aws_as_user ledgerlens-report s3api list-objects-v2 --bucket harborline-reports --prefix reports/ >/dev/null 2>&1; then
  echo "ledgerlens-report can no longer list harborline-reports. Keep the existing listing permission."
  exit 1
fi

# The actual symptom: downloading a report.
if ! out="$(aws_as_user ledgerlens-report s3api get-object --bucket harborline-reports \
      --key reports/2025-q3.csv "$dest" 2>&1)"; then
  echo "Downloading reports/2025-q3.csv as ledgerlens-report still fails."
  echo "The policy lets the user see names in the bucket, but nothing yet lets it read the contents of an object."
  echo "S3 said: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if ! grep -q 'SIN-LAX' "$dest"; then
  echo "The download succeeded but the content is not the Q3 report. Did the data change?"
  exit 1
fi

# Least privilege checks.
if aws_as_user ledgerlens-report s3api get-object --bucket harborline-payroll \
     --key payroll/2025-09.csv "$dest" >/dev/null 2>&1; then
  echo "The dashboard can now read harborline-payroll. Scope the permission to the reports bucket only."
  exit 1
fi
if aws_as_user ledgerlens-report s3api put-object --bucket harborline-reports \
     --key reports/tamper.csv --body "$probe" >/dev/null 2>&1; then
  echo "The dashboard can write to the reports bucket. It only needs to read."
  exit 1
fi
if aws_as_user ledgerlens-report s3api delete-object --bucket harborline-reports \
     --key reports/2025-q3.csv >/dev/null 2>&1; then
  echo "The dashboard can delete reports. Grant read access only."
  exit 1
fi

echo "ledgerlens-report reads the Q3 report, still lists the bucket, and stays out of payroll. Finance is happy."
