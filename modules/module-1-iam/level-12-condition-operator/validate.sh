#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dest="$(mktemp)"
trap 'rm -f "$dest"' EXIT
clerk() { aws_as_user ashgrove-clerk "$@"; }
count() { clerk s3api list-objects-v2 --bucket ashgrove-case-files --prefix "$1" --query 'length(Contents)' --output text 2>/dev/null; }

top="$(count matters/2025/ || true)"
if [ "$top" != "2" ]; then
  echo "Listing matters/2025/ as ashgrove-clerk did not return the two 2025 files (got: ${top:-an error})."
  echo "The Condition has to match the prefix the clerk sends; compare how the value is written with how the operator compares values."
  exit 1
fi
sub="$(count matters/2025/smith-v-jones/ || true)"
if [ "$sub" != "1" ]; then
  echo "Listing matters/2025/smith-v-jones/ failed (got: ${sub:-an error}). Every folder below matters/2025/ must be browsable."
  exit 1
fi
if ! clerk s3api get-object --bucket ashgrove-case-files --key matters/2025/okafor-estate/will.txt "$dest" >/dev/null 2>&1; then
  echo "The clerk can list the 2025 folders but not open a file from them."
  exit 1
fi

if [ -n "$(count matters/2024/ || true)" ]; then
  echo "ashgrove-clerk can list matters/2024/. The restriction to 2025 is gone."
  exit 1
fi
if clerk s3api list-objects-v2 --bucket ashgrove-case-files >/dev/null 2>&1; then
  echo "ashgrove-clerk can list the whole bucket. A listing without a prefix must be refused."
  exit 1
fi

echo "The clerk browses and reads matters/2025/ only. 2024 and the bucket root stay closed."
