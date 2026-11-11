#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Two customer managed keys: the right one and a look-alike for billing.
phi_key="$(aws_local kms create-key --description "Riverside PHI scans" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/riverside-phi --target-key-id "$phi_key"
bill_key="$(aws_local kms create-key --description "Riverside billing exports" --query KeyMetadata.KeyId --output text)"
aws_local kms create-alias --alias-name alias/riverside-billing --target-key-id "$bill_key"

aws_local s3 mb s3://riverside-scans >/dev/null
echo "DICOM bytes - patient 0042" > "$work/scan.dcm"
aws_local s3 cp "$work/scan.dcm" s3://riverside-scans/scans/mri-0042.dcm >/dev/null

echo "riverside-scans has no default encryption."
