#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=nimbus-build-artifacts
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "build output $(date +%s)" > "$work/payload.txt"

put_as() { # user key
  aws_as_user "$1" s3api put-object --bucket "$B" --key "$2" --body "$work/payload.txt" 2>&1
}

if ! out="$(put_as ci-runner artifacts/build-4412.txt)"; then
  echo "ci-runner still cannot publish to artifacts/: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if ! aws_as_user ci-runner s3api get-object --bucket "$B" --key artifacts/build-4412.txt "$work/back.txt" >/dev/null 2>&1; then
  echo "ci-runner can publish but lost the ability to read builds back."
  exit 1
fi
if put_as ci-runner releases/leak.txt >/dev/null; then
  echo "ci-runner can write under releases/. Publishing belongs only under artifacts/."
  exit 1
fi
if put_as ci-runner rogue-top-level.txt >/dev/null; then
  echo "ci-runner can write anywhere in the bucket. Limit the grant to the artifacts/ prefix."
  exit 1
fi
if aws_as_user ci-runner s3api delete-object --bucket "$B" --key artifacts/build-4411.txt >/dev/null 2>&1; then
  echo "ci-runner can delete objects. The pipeline only needs to upload."
  exit 1
fi
if ! put_as release-manager releases/v7.2.0.txt >/dev/null; then
  echo "release-manager can no longer publish to releases/. Do not remove the existing release statement."
  exit 1
fi
echo "ci-runner publishes to artifacts/, reads builds, and nothing more. releases/ still belongs to release-manager."
