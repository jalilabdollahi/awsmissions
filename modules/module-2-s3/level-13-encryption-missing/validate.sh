#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=riverside-scans
phi_id="$(aws_local kms describe-key --key-id alias/riverside-phi --query KeyMetadata.KeyId --output text)"
bill_id="$(aws_local kms describe-key --key-id alias/riverside-billing --query KeyMetadata.KeyId --output text)"

enc="$(aws_local s3api get-bucket-encryption --bucket "$B" --output json 2>/dev/null || true)"
if [ -z "$enc" ]; then
  echo "riverside-scans still has no default encryption configuration."
  exit 1
fi

# Resolve whatever the player configured (alias, key id or ARN) to a key id.
parsed="$(printf '%s' "$enc" | python3 -c '
import json, sys
rule = json.load(sys.stdin)["ServerSideEncryptionConfiguration"]["Rules"][0]
d = rule["ApplyServerSideEncryptionByDefault"]
print(d.get("SSEAlgorithm", ""), d.get("KMSMasterKeyID", "-"), str(rule.get("BucketKeyEnabled", False)).lower())')"
algo="$(printf '%s' "$parsed" | awk '{print $1}')"
keyref="$(printf '%s' "$parsed" | awk '{print $2}')"
bucketkey="$(printf '%s' "$parsed" | awk '{print $3}')"

if [ "$algo" = "AES256" ]; then
  echo "The bucket uses SSE-S3 (AES256). Policy requires SSE-KMS with the clinic's own key."
  exit 1
fi
if [ "$keyref" = "-" ]; then
  echo "SSE-KMS is configured without a key id, which means the AWS managed key. The clinic's own key is required."
  exit 1
fi
cfg_id="$(aws_local kms describe-key --key-id "$keyref" --query KeyMetadata.KeyId --output text 2>/dev/null || true)"
if [ "$cfg_id" = "$bill_id" ]; then
  echo "Default encryption uses the billing key. Scans must use the PHI key."
  exit 1
fi
if [ "$cfg_id" != "$phi_id" ]; then
  echo "Default encryption is set, but not to the customer managed key alias/riverside-phi."
  exit 1
fi
if [ "$bucketkey" != "true" ]; then
  echo "Bucket Keys are not enabled for the default encryption rule."
  exit 1
fi

# The scan uploaded before the audit must be encrypted too.
head="$(aws_local s3api head-object --bucket "$B" --key scans/mri-0042.dcm --query '[ServerSideEncryption,SSEKMSKeyId]' --output text 2>/dev/null || true)"
sse="$(printf '%s' "$head" | awk '{print $1}')"
objkey="$(printf '%s' "$head" | awk '{print $2}')"
if [ "$sse" != "aws:kms" ]; then
  echo "The existing scan scans/mri-0042.dcm is still stored unencrypted. Default encryption only applies to new uploads."
  exit 1
fi
obj_id="$(aws_local kms describe-key --key-id "$objkey" --query KeyMetadata.KeyId --output text 2>/dev/null || true)"
if [ "$obj_id" != "$phi_id" ]; then
  echo "The existing scan is encrypted, but with a different key than alias/riverside-phi."
  exit 1
fi
echo "New scans default to SSE-KMS with the PHI key (Bucket Keys on) and the existing scan was re-encrypted."
