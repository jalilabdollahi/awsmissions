#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://ledgerly-contracts >/dev/null

# The signed original, then the accidental overwrite.
echo "ORBIT MSA - signed original, 36 month term" > "$work/signed.txt"
echo "ORBIT MSA - paralegal draft, term blank" > "$work/draft.txt"
aws_local s3 cp "$work/signed.txt" s3://ledgerly-contracts/orbit/msa.txt >/dev/null
aws_local s3 cp "$work/draft.txt" s3://ledgerly-contracts/orbit/msa.txt >/dev/null

# The service may already read and list older revisions - there just are none.
aws_local iam create-user --user-name contract-svc >/dev/null
aws_local iam put-user-policy --user-name contract-svc --policy-name contracts-rw \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": ["s3:ListBucket", "s3:ListBucketVersions"], "Resource": "arn:aws:s3:::ledgerly-contracts"},
      {"Effect": "Allow", "Action": ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], "Resource": "arn:aws:s3:::ledgerly-contracts/*"}
    ]
  }'

echo "The signed Orbit MSA has been overwritten and no earlier copy exists."
