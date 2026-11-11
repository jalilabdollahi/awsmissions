#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:lumen-order-screening"
QUEUE="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/lumen-review-desk"

aws_local sqs purge-queue --queue-url "$QUEUE" >/dev/null 2>&1 || true

order_no="LW-$(date +%s)"
input="{\"orderId\":\"$order_no\",\"customer\":{\"name\":\"Marlowe & Daughters\",\"accountAgeDays\":12},\"items\":[{\"sku\":\"LMP-3\",\"qty\":4,\"unitPrice\":310},{\"sku\":\"CBL-9\",\"qty\":20,\"unitPrice\":7}]}"
ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" --input "$input" --query executionArn --output text)"

done_yet() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
wait_for "the screening execution" 40 done_yet || exit 1

status="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
if [ "$status" != "SUCCEEDED" ]; then
  echo "The execution ended as $status: $(aws_local stepfunctions describe-execution --execution-arn "$ex" --query '[error,cause]' --output text | cut -c1-240)"
  exit 1
fi

msg="$(aws_local sqs receive-message --queue-url "$QUEUE" --max-number-of-messages 1 --wait-time-seconds 3 \
  --query 'Messages[0].Body' --output text)"
if [ -z "$msg" ] || [ "$msg" = "None" ]; then
  echo "The execution succeeded but nothing arrived on lumen-review-desk."
  exit 1
fi

echo "$msg" | python3 -c '
import json, sys

def walk(node, key=None):
    """Yield (key, value) for every leaf of a JSON document."""
    if isinstance(node, dict):
        for k, v in node.items():
            yield from walk(v, k)
    elif isinstance(node, list):
        for v in node:
            yield from walk(v, key)
    else:
        yield key, node

order_no = sys.argv[1]
try:
    doc = json.loads(sys.stdin.read())
except ValueError:
    print("The review-desk message is not valid JSON.")
    sys.exit(1)
leaves = list(walk(doc))
missing = []
if not any(k == "orderId" and v == order_no for k, v in leaves):
    missing.append("the orderId")
if not any(k == "name" and v == "Marlowe & Daughters" for k, v in leaves):
    missing.append("the customer")
if not any(k == "sku" and v == "LMP-3" for k, v in leaves):
    missing.append("the items")
# 4*310 + 20*7 = 1380 -> 27, plus 25 for an account under 30 days old
if not any(k == "riskScore" and v == 52 for k, v in leaves):
    missing.append("the fraud score (expected riskScore 52)")
if missing:
    print("The message on lumen-review-desk is incomplete, it lacks: " + ", ".join(missing) + ".")
    sys.exit(1)
' "$order_no"

echo "The review desk now receives the full order ($order_no) together with its fraud score."
