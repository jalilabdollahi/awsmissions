#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
B=sunrise-photos

aws_local s3api create-bucket --bucket "$B" >/dev/null
# New buckets reject ACLs; the legacy uploader needed them, so ownership was relaxed.
aws_local s3api put-bucket-ownership-controls --bucket "$B" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerPreferred}]'

echo "gallery photo" > "$work/p.jpg"
aws_local s3api put-object --bucket "$B" --key galleries/smith-wedding/001.jpg --body "$work/p.jpg" --acl public-read >/dev/null
aws_local s3api put-object --bucket "$B" --key galleries/smith-wedding/002.jpg --body "$work/p.jpg" --acl public-read >/dev/null
aws_local s3api put-object --bucket "$B" --key galleries/smith-wedding/contract.pdf --body "$work/p.jpg" >/dev/null
aws_local s3api put-bucket-acl --bucket "$B" --acl public-read

aws_local iam create-user --user-name renderer-app >/dev/null
aws_local iam put-user-policy --user-name renderer-app --policy-name gallery-read \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {"Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::sunrise-photos"},
      {"Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::sunrise-photos/galleries/*"}
    ]
  }'

echo "sunrise-photos exposes its bucket and two photos to the public through ACLs."
