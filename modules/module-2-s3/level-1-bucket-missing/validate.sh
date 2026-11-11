#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

WANTED="harborline-manifests-2026"
if ! aws_local s3api head-bucket --bucket "$WANTED" >/dev/null 2>&1; then
  echo "The bucket $WANTED still does not exist. Compare the name in the service configuration with 'aws s3 ls' character by character."
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
stamp="manifest check $(date +%s)"
printf '%s\n' "$stamp" > "$work/in.txt"

if ! out="$(aws_as_user ingest-bot s3api put-object --bucket "$WANTED" --key manifests/healthcheck.txt \
      --body "$work/in.txt" 2>&1)"; then
  echo "The bucket exists, but ingest-bot cannot write to it: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
if ! aws_as_user ingest-bot s3api get-object --bucket "$WANTED" --key manifests/healthcheck.txt "$work/out.txt" >/dev/null 2>&1; then
  echo "ingest-bot wrote the manifest but could not read it back."
  exit 1
fi
if ! cmp -s "$work/in.txt" "$work/out.txt"; then
  echo "The manifest read back from $WANTED does not match what was written."
  exit 1
fi
echo "ingest-bot stores and reads manifests in $WANTED. The scanners are online again."
