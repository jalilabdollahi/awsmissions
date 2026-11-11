#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

aws_local s3 mb s3://nimbus-build-artifacts >/dev/null
echo "build 4411 ok" > "$work/b.txt"
aws_local s3 cp "$work/b.txt" s3://nimbus-build-artifacts/artifacts/build-4411.txt >/dev/null

aws_local iam create-user --user-name ci-runner >/dev/null
aws_local iam create-user --user-name release-manager >/dev/null

aws_local s3api put-bucket-policy --bucket nimbus-build-artifacts \
  --policy "file://$MISSION_DIR/workspace/bucket-policy.json"

echo "ci-runner can pull builds, but every publish fails."
