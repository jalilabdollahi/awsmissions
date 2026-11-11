#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The migration script created a bucket with a near-identical name (singular).
aws_local s3 mb s3://harborline-manifest-2026 >/dev/null
printf 'MV Aurora Borealis | 41 containers\n' > "${TMPDIR:-/tmp}/aurora-manifest.txt"
aws_local s3 cp "${TMPDIR:-/tmp}/aurora-manifest.txt" s3://harborline-manifest-2026/manifests/aurora.txt >/dev/null
rm -f "${TMPDIR:-/tmp}/aurora-manifest.txt"

# The service identity. Its policy was written against the plural bucket name.
aws_local iam create-user --user-name ingest-bot >/dev/null
aws_local iam put-user-policy --user-name ingest-bot --policy-name manifest-io \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": ["s3:ListBucket"], "Resource": "arn:aws:s3:::harborline-manifests-2026"},
      {"Effect": "Allow", "Action": ["s3:PutObject", "s3:GetObject"], "Resource": "arn:aws:s3:::harborline-manifests-2026/manifests/*"}
    ]
  }'

echo "ingest-bot is restarting in a loop: NoSuchBucket."
