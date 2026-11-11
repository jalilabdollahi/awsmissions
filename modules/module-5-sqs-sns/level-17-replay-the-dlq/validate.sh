#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

main="$(aws_local sqs get-queue-url --queue-name crescent-invoices --query QueueUrl --output text 2>/dev/null || true)"
dlq="$(aws_local sqs get-queue-url --queue-name crescent-invoices-dlq --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$main" ] || [ -z "$dlq" ]; then
  echo "crescent-invoices and crescent-invoices-dlq must both still exist."
  exit 1
fi

peek() {
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' | sort || true
}

# A message move task works asynchronously, so give it a moment to drain the DLQ.
drained() { [ "$(peek "$dlq" | grep -c '^{' || true)" -eq 0 ]; }
wait_for "DLQ to drain" 10 drained 2>/dev/null || true
left="$(peek "$dlq" | grep -c '^{' || true)"
if [ "$left" -gt 0 ]; then
  echo "crescent-invoices-dlq still holds $left invoice(s). They all have to go back to the main queue."
  exit 1
fi

# Poll briefly: a message move task works asynchronously.
settled() { [ "$(peek "$main" | grep -c 'CR-41' || true)" -ge 6 ]; }
if ! wait_for "invoices in main queue" 10 settled; then
  echo "The DLQ is empty but crescent-invoices does not hold all six invoices. Messages must be moved, not deleted."
  exit 1
fi

report="$(peek "$main" | python3 -c '
import json, sys
seen = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    d = json.loads(line)
    seen.append((d.get("invoice"), d.get("currency"), d.get("state")))
want = sorted(("CR-%d" % n, "EUR", "failed") for n in range(4101, 4107))
if sorted(seen) == want:
    print("ok")
elif len(seen) != len(set(seen)) or len(seen) > 6:
    print("duplicates")
else:
    print("changed")')"
case "$report" in
  ok) echo "All six invoices are back in crescent-invoices exactly once and unchanged; the DLQ is empty." ;;
  duplicates) echo "Some invoices appear more than once in crescent-invoices."; exit 1 ;;
  *) echo "The invoices in crescent-invoices are not the original six, unchanged."; exit 1 ;;
esac
