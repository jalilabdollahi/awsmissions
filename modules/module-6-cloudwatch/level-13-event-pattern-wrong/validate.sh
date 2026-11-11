#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

queue="$(aws_local sqs get-queue-url --queue-name gold-concierge --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue gold-concierge is gone."
  exit 1
fi
if ! aws_local events describe-rule --name quillshop-gold-orders >/dev/null 2>&1; then
  echo "The rule quillshop-gold-orders no longer exists. Correct its pattern instead."
  exit 1
fi

run="$(date +%s)$$"
place() {
  # place TIER SOURCE DETAIL-TYPE ORDER
  local detail
  detail="$(printf '{"tier":"%s","order":"%s"}' "$1" "$4" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  aws_local events put-events --entries \
    "[{\"Source\":\"$2\",\"DetailType\":\"$3\",\"Detail\":$detail}]" >/dev/null
}
place gold   quillshop.orders OrderPlaced    "g-$run"
place silver quillshop.orders OrderPlaced    "s-$run"
place gold   quillshop.orders OrderCancelled "c-$run"

peek() {
  aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null
}
for _ in $(seq 1 10); do
  peek | grep -q "g-$run" && break
  sleep 1
done
all="$(peek)"
if ! printf '%s' "$all" | grep -q "g-$run"; then
  echo "A gold OrderPlaced event from quillshop.orders was not forwarded. Compare the pattern, value by value, with the real event (source, detail-type, detail.tier). Matching is exact and case-sensitive."
  exit 1
fi
sleep 1
all="$(peek)"
if printf '%s' "$all" | grep -q "s-$run"; then
  echo "A silver-tier order was forwarded. The rule must still filter on the customer tier."
  exit 1
fi
if printf '%s' "$all" | grep -q "c-$run"; then
  echo "An OrderCancelled event was forwarded. The rule must stay limited to OrderPlaced."
  exit 1
fi

echo "Gold-tier OrderPlaced events reach gold-concierge, and nothing else does."
