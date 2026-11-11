#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

file="$(mktemp)"
trap 'rm -f "$file"' EXIT
echo "frame $(date +%s)" > "$file"
render() { aws_as_user vantage-render "$@"; }

# Legitimate work must keep working.
for b in vantage-assets vantage-assets-eu; do
  if ! render s3api get-object --bucket "$b" --key seed/file.txt "$file" >/dev/null 2>&1; then
    echo "vantage-render can no longer read $b. Tightening must not break the real job."
    exit 1
  fi
done
if ! render s3api put-object --bucket vantage-renders --key out/clip-001.mp4 --body "$file" >/dev/null 2>&1; then
  echo "vantage-render can no longer write finished videos to vantage-renders."
  exit 1
fi

# The point of the mission.
leaks=""
for b in vantage-payroll-exports vantage-legal-hold; do
  if render s3api get-object --bucket "$b" --key seed/file.txt "$file" >/dev/null 2>&1; then
    leaks="$leaks $b(read)"
  fi
  if render s3api put-object --bucket "$b" --key seed/injected.txt --body "$file" >/dev/null 2>&1; then
    leaks="$leaks $b(write)"
  fi
done
if [ -n "$leaks" ]; then
  echo "vantage-render still reaches buckets it has no business with:$leaks"
  echo "Compare what the policy's Resource entries can match with what the job really needs."
  exit 1
fi

# Write access to the asset buckets and read from renders were never part of the job.
if render s3api put-object --bucket vantage-assets --key seed/overwrite.txt --body "$file" >/dev/null 2>&1; then
  echo "vantage-render can overwrite source assets. Writes belong in vantage-renders only."
  exit 1
fi
if render s3api get-object --bucket vantage-renders --key out/clip-001.mp4 "$file" >/dev/null 2>&1; then
  echo "vantage-render can read back the renders bucket; it only needs to write there."
  exit 1
fi

echo "vantage-render reads assets, writes renders, and no longer reaches anything else with a vantage- name."
