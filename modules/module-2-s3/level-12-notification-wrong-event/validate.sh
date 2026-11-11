#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=snapfolio-gallery
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "jpeg bytes" > "$work/img"

# keys_in QUEUE -> prints "EventName key" for every record, then deletes the messages.
keys_in() {
  local url="$AWS_ENDPOINT_URL/$ACCOUNT_ID/$1" out
  while :; do
    out="$(aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 \
      --wait-time-seconds 1 --output json 2>/dev/null || true)"
    [ -n "$out" ] || break
    if ! printf '%s' "$out" | python3 -c '
import json, sys
msgs = json.load(sys.stdin).get("Messages", [])
for m in msgs:
    try:
        for rec in json.loads(m["Body"]).get("Records", []):
            print(rec["eventName"], rec["s3"]["object"]["key"])
    except Exception:
        pass
sys.exit(0 if msgs else 3)'; then break; fi
    printf '%s' "$out" | python3 -c '
import json, sys
for m in json.load(sys.stdin).get("Messages", []):
    print(m["ReceiptHandle"])' | while read -r rh; do
      aws_local sqs delete-message --queue-url "$url" --receipt-handle "$rh" >/dev/null 2>&1 || true
    done
  done
}

keys_in thumbnail-jobs >/dev/null
keys_in deletion-audit >/dev/null
s="$(date +%s)"

# Round 1: uploads create, originals get created and deleted, uploads get deleted.
aws_local s3api put-object --bucket "$B" --key "uploads/p-$s.jpg" --body "$work/img" >/dev/null
aws_local s3api put-object --bucket "$B" --key "originals/o-$s.jpg" --body "$work/img" >/dev/null
aws_local s3api delete-object --bucket "$B" --key "originals/o-$s.jpg" >/dev/null
aws_local s3api delete-object --bucket "$B" --key "uploads/p-$s.jpg" >/dev/null
sleep 3
thumbs="$(keys_in thumbnail-jobs)"
audit="$(keys_in deletion-audit)"

if ! printf '%s\n' "$thumbs" | grep -q "^ObjectCreated.* uploads/p-$s.jpg$"; then
  echo "Uploading to uploads/ did not create a message in thumbnail-jobs."
  exit 1
fi
if printf '%s\n' "$thumbs" | grep -q "^ObjectRemoved"; then
  echo "thumbnail-jobs still receives deletion events. A thumbnail worker has nothing to do when a photo is deleted."
  exit 1
fi
if printf '%s\n' "$thumbs" | grep -q "originals/"; then
  echo "thumbnail-jobs now receives events for originals/. Only uploads/ should trigger thumbnails."
  exit 1
fi
if ! printf '%s\n' "$audit" | grep -q "^ObjectRemoved.* originals/o-$s.jpg$"; then
  echo "The deletion audit no longer records deletes of originals/. That rule had to stay as it was."
  exit 1
fi
if printf '%s\n' "$audit" | grep -q "^ObjectCreated"; then
  echo "deletion-audit now receives creation events. It must only see deletes."
  exit 1
fi
echo "Uploads create thumbnail jobs, deletes of originals are still audited, and neither queue gets the other's events."
