#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

B=acornpay-invoices
QURL="$AWS_ENDPOINT_URL/$ACCOUNT_ID/invoice-intake"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
echo "%PDF-1.4 probe" > "$work/body"

# Read and discard everything currently in the queue, printing the S3 keys seen.
drain() {
  local out
  while :; do
    out="$(aws_local sqs receive-message --queue-url "$QURL" --max-number-of-messages 10 \
      --wait-time-seconds 1 --output json 2>/dev/null || true)"
    [ -n "$out" ] || break
    printf '%s' "$out" | python3 -c '
import json, sys
msgs = json.load(sys.stdin).get("Messages", [])
for m in msgs:
    try:
        for rec in json.loads(m["Body"]).get("Records", []):
            print(rec["s3"]["object"]["key"])
    except Exception:
        pass
sys.exit(0 if msgs else 3)' || break
    # delete what we read
    printf '%s' "$out" | python3 -c '
import json, sys
for m in json.load(sys.stdin).get("Messages", []):
    print(m["ReceiptHandle"])' | while read -r rh; do
      aws_local sqs delete-message --queue-url "$QURL" --receipt-handle "$rh" >/dev/null 2>&1 || true
    done
  done
}

drain >/dev/null
stamp="$(date +%s)"
aws_as_user scanner-svc s3api put-object --bucket "$B" --key "inbox/acme-$stamp.pdf" --body "$work/body" >/dev/null
aws_as_user scanner-svc s3api put-object --bucket "$B" --key "inbox/cover-$stamp.txt" --body "$work/body" >/dev/null
aws_as_user scanner-svc s3api put-object --bucket "$B" --key "archive/old-$stamp.pdf" --body "$work/body" >/dev/null
sleep 3
seen="$(drain)"

if ! printf '%s\n' "$seen" | grep -qx "inbox/acme-$stamp.pdf"; then
  echo "A PDF uploaded to inbox/ produced no message in invoice-intake."
  exit 1
fi
if printf '%s\n' "$seen" | grep -q "cover-$stamp.txt"; then
  echo "A .txt file in inbox/ also created a job. Only .pdf objects should trigger the robot."
  exit 1
fi
if printf '%s\n' "$seen" | grep -q "archive/old-$stamp.pdf"; then
  echo "A PDF outside inbox/ also created a job. Only inbox/ should trigger the robot."
  exit 1
fi
echo "A new inbox/*.pdf reaches invoice-intake, and nothing else does."
