#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=quillhouse-partner-drop
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "partner file $(date +%s)" > "$work/up.txt"

as_partner() { aws_as_user partner-sync "$@"; }

if ! as_partner s3api list-objects-v2 --bucket "$B" --prefix outbound/ >/dev/null 2>&1; then
  echo "partner-sync cannot list outbound/."
  exit 1
fi
if ! as_partner s3api list-objects-v2 --bucket "$B" --prefix inbound/ >/dev/null 2>&1; then
  echo "partner-sync cannot list inbound/."
  exit 1
fi
if ! as_partner s3api get-object --bucket "$B" --key outbound/run-7731.txt "$work/dl.txt" >/dev/null 2>&1; then
  echo "partner-sync cannot download outbound/run-7731.txt."
  exit 1
fi
if ! as_partner s3api put-object --bucket "$B" --key "inbound/reply-$(date +%s).txt" --body "$work/up.txt" >/dev/null 2>&1; then
  echo "partner-sync cannot upload to inbound/."
  exit 1
fi

# Everything that must remain forbidden.
if as_partner s3api get-object --bucket "$B" --key internal/catalogue-2027.txt "$work/x" >/dev/null 2>&1; then
  echo "partner-sync can read internal/. Downloads are only for outbound/."
  exit 1
fi
if as_partner s3api list-objects-v2 --bucket "$B" --prefix internal/ >/dev/null 2>&1; then
  echo "partner-sync can list internal/. The list grant must stay limited to the two drop folders."
  exit 1
fi
if as_partner s3api list-objects-v2 --bucket "$B" >/dev/null 2>&1; then
  echo "partner-sync can list the whole bucket. A listing must always name one of the two allowed prefixes."
  exit 1
fi
if as_partner s3api put-object --bucket "$B" --key outbound/tamper.txt --body "$work/up.txt" >/dev/null 2>&1; then
  echo "partner-sync can write to outbound/. Uploads belong in inbound/ only."
  exit 1
fi
if as_partner s3api delete-object --bucket "$B" --key outbound/run-7731.txt >/dev/null 2>&1; then
  echo "partner-sync can delete objects."
  exit 1
fi
if aws_as_user vendor-other s3api get-object --bucket "$B" --key outbound/run-7731.txt "$work/y" >/dev/null 2>&1; then
  echo "An unrelated user can download from the bucket. The grants must name partner-sync only."
  exit 1
fi
echo "partner-sync can list, download from outbound/ and upload to inbound/ - and nothing else."
