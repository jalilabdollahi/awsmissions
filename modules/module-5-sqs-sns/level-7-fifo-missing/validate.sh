#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! url="$(aws_local sqs get-queue-url --queue-name ironwood-ledger-events.fifo --query QueueUrl --output text 2>/dev/null)"; then
  echo "There is no queue ironwood-ledger-events.fifo yet. A queue's type cannot be changed after creation, so the ordered queue has to be a new one."
  exit 1
fi

fifo="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names FifoQueue \
  --query 'Attributes.FifoQueue' --output text 2>/dev/null || true)"
if [ "$fifo" != "true" ]; then
  echo "The queue has a .fifo name but is not a FIFO queue (FifoQueue attribute is '$fifo'). The suffix alone does not give ordering; the queue must be created as FIFO."
  exit 1
fi

# Two accounts interleaved; every account's events must come back in send order.
run="$(date +%s)-$$"
n=1
while [ "$n" -le 6 ]; do
  for acct in acct-17 acct-42; do
    aws_local sqs send-message --queue-url "$url" --message-group-id "$acct-$run" \
      --message-deduplication-id "$acct-$run-$n" --message-body "$acct-$run:$n" >/dev/null
  done
  n=$((n + 1))
done

got=""
tries=0
while [ "$tries" -lt 8 ]; do
  batch="$(aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 --visibility-timeout 30 \
    --query 'Messages[].[Body,ReceiptHandle]' --output text 2>/dev/null || true)"
  [ -z "$batch" ] || [ "$batch" = "None" ] && break
  while read -r body handle; do
    got="$got $body"
    aws_local sqs delete-message --queue-url "$url" --receipt-handle "$handle" >/dev/null 2>&1 || true
  done <<EOT
$batch
EOT
  tries=$((tries + 1))
done

result="$(RUN="$run" GOT="$got" python3 - <<'PY'
import os
run = os.environ["RUN"]
seen = {}
for item in os.environ["GOT"].split():
    key, _, seq = item.rpartition(":")
    if key.endswith(run):
        seen.setdefault(key, []).append(int(seq))
if len(seen) != 2 or any(len(v) != 6 for v in seen.values()):
    print("missing")
elif all(v == sorted(v) for v in seen.values()):
    print("ordered")
else:
    print("shuffled")
PY
)"
case "$result" in
  ordered) echo "ironwood-ledger-events.fifo delivers each account's events in the order they were sent." ;;
  missing) echo "Not all test events came back from the FIFO queue; check it is receiving and handing out messages."; exit 1 ;;
  *) echo "Events within one message group came back out of order."; exit 1 ;;
esac
