#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
echo 'x' > "$dest"
reviewer() { aws_as_user proofreader "$@"; }

if ! aws_local s3api get-bucket-policy --bucket harborprint-proofs >/dev/null 2>&1; then
  echo "The bucket has no policy any more. Repair it rather than removing it; the reviewer has no IAM permissions of their own."
  exit 1
fi

if ! reviewer s3api list-objects-v2 --bucket harborprint-proofs --prefix proofs/ >/dev/null 2>&1; then
  echo "proofreader still cannot list harborprint-proofs."
  echo "The user has no identity policy, so this must be granted by the bucket policy: check the Principal and which ARN the statement applies to."
  exit 1
fi
if ! out="$(reviewer s3api get-object --bucket harborprint-proofs --key proofs/order-7731.pdf "$dest" 2>&1)"; then
  echo "proofreader can list but cannot download a proof: $(printf '%s' "$out" | tail -1)"
  echo "Listing and reading apply to different kinds of S3 resources."
  exit 1
fi

if aws_as_user proof-intern s3api get-object --bucket harborprint-proofs --key proofs/order-7731.pdf "$dest" >/dev/null 2>&1 \
   || aws_as_user proof-intern s3api list-objects-v2 --bucket harborprint-proofs >/dev/null 2>&1; then
  echo "proof-intern can reach the bucket. The policy is open to more principals than the one reviewer."
  exit 1
fi
if reviewer s3api put-object --bucket harborprint-proofs --key proofs/forged.pdf --body "$dest" >/dev/null 2>&1; then
  echo "The reviewer can upload to the proofs bucket. Read access only."
  exit 1
fi
if reviewer s3api delete-object --bucket harborprint-proofs --key proofs/order-7731.pdf >/dev/null 2>&1; then
  echo "The reviewer can delete proofs. Read access only."
  exit 1
fi

echo "proofreader lists and reads the proofs through the bucket policy; proof-intern is still locked out."
