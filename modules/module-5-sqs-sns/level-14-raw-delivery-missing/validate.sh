#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:delta-cart-events"
queue="$(aws_local sqs get-queue-url --queue-name delta-web-analytics --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue delta-web-analytics is gone."
  exit 1
fi

run="$(date +%s)$$"
aws_local sns publish --topic-arn "$topic_arn" --message "{\"sku\":\"WEB-$run\",\"qty\":2}" \
  --message-attributes '{"channel":{"DataType":"String","StringValue":"web"}}' >/dev/null
aws_local sns publish --topic-arn "$topic_arn" --message "{\"sku\":\"APP-$run\",\"qty\":1}" \
  --message-attributes '{"channel":{"DataType":"String","StringValue":"mobile"}}' >/dev/null

bodies() {
  aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | tr '\t' '\n' || true
}
web_arrived() { bodies | grep -q "WEB-$run"; }
if ! wait_for "web delivery" 8 web_arrived; then
  echo "The web event did not reach delta-web-analytics at all."
  exit 1
fi
sleep 1
all="$(bodies)"

if printf '%s\n' "$all" | grep -q "APP-$run"; then
  echo "A mobile event arrived in the web analytics queue: the channel = web filter is no longer in effect."
  exit 1
fi

verdict="$(BODIES="$all" SKU="WEB-$run" python3 - <<'PY'
import json, os
for line in os.environ["BODIES"].splitlines():
    if os.environ["SKU"] not in line:
        continue
    try:
        doc = json.loads(line)
    except ValueError:
        print("notjson"); raise SystemExit
    if doc.get("sku") == os.environ["SKU"] and doc.get("qty") == 2:
        print("raw")
    else:
        print("wrapped")
    raise SystemExit
print("missing")
PY
)"
case "$verdict" in
  raw) echo "The collector gets the bare cart event, and only web events. Parsing works again." ;;
  *) echo "The message body is not the bare cart event: the collector still receives something wrapped around it (SNS 'Type: Notification' envelope)."; exit 1 ;;
esac
