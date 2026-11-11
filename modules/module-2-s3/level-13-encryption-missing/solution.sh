#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3api put-bucket-encryption --bucket riverside-scans \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms", "KMSMasterKeyID": "alias/riverside-phi"},
      "BucketKeyEnabled": true
    }]
  }'

# Existing object: rewrite it in place with the same key.
aws_local s3api copy-object --bucket riverside-scans --key scans/mri-0042.dcm \
  --copy-source riverside-scans/scans/mri-0042.dcm \
  --server-side-encryption aws:kms --ssekms-key-id alias/riverside-phi >/dev/null
