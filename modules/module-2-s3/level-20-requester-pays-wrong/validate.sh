#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

wrong=""
for b in $(aws_local s3api list-buckets --query 'Buckets[?starts_with(Name, `ridgeline-`)].Name' --output text); do
  payer="$(aws_local s3api get-bucket-request-payment --bucket "$b" --query Payer --output text)"
  if [ "$b" = "ridgeline-open-data" ]; then
    if [ "$payer" != "Requester" ]; then
      echo "ridgeline-open-data is set to $payer. The public dataset is supposed to stay on Requester Pays."
      exit 1
    fi
  elif [ "$payer" != "BucketOwner" ]; then
    wrong="$wrong $b"
  fi
done
if [ -n "$wrong" ]; then
  echo "Still on Requester Pays by mistake:$wrong"
  exit 1
fi

# A partner downloading with an ordinary request (no requester-pays header) must work.
if ! aws_as_user feed-consumer s3api get-object --bucket ridgeline-partner-feeds --key q3/feed.csv "$work/f" >/dev/null 2>&1; then
  echo "feed-consumer cannot download the partner feed with a normal request."
  exit 1
fi
echo "Only ridgeline-open-data still bills its downloaders; every other bucket is paid for by its owner again."
