#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:brightline-po-approval"
base="$AWS_ENDPOINT_URL/${ACCOUNT_ID}"
approvals="$base/brightline-approvals"
issued="$base/brightline-issued"
notices="$base/brightline-requester-notices"
for q in "$approvals" "$issued" "$notices"; do aws_local sqs purge-queue --queue-url "$q" >/dev/null 2>&1 || true; done

started=""
trap 'for e in $started; do aws_local stepfunctions stop-execution --execution-arn "$e" >/dev/null 2>&1 || true; done' EXIT

start_po() { # poId -> execution arn
  local arn
  arn="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
    --input "{\"poId\":\"$1\",\"amount\":4800,\"requester\":\"robin.vale\"}" --query executionArn --output text)"
  started="$started $arn"
  echo "$arn"
}

# Reads the approval request for a PO from the queue and returns every string value it carries.
request_strings() { # poId
  local i=0 body=""
  while [ "$i" -lt 20 ]; do
    body="$(aws_local sqs receive-message --queue-url "$approvals" --max-number-of-messages 10 \
      --visibility-timeout 0 --query 'Messages[].Body' --output text | tr '\t' '\n' | grep "$1" | head -1 || true)"
    [ -n "$body" ] && break
    sleep 1; i=$((i + 1))
  done
  [ -n "$body" ] || return 1
  printf '%s' "$body" | python3 -c '
import json, sys
raw = sys.stdin.read()
def leaves(node):
    if isinstance(node, dict):
        for v in node.values():
            yield from leaves(v)
    elif isinstance(node, list):
        for v in node:
            yield from leaves(v)
    elif isinstance(node, str):
        yield node
try:
    for s in leaves(json.loads(raw)):
        print(s)
except ValueError:
    print(raw)
'
}

# Answer the request with a callback; $1 = poId, $2 = success|failure. Prints "ok" or a reason.
answer() {
  local candidate
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if [ "$2" = "success" ]; then
      if aws_local stepfunctions send-task-success --task-token "$candidate" \
           --task-output '{"approvedBy":"dana.whitlock"}' >/dev/null 2>&1; then echo ok; return 0; fi
    else
      if aws_local stepfunctions send-task-failure --task-token "$candidate" \
           --error Rejected --cause "over budget" >/dev/null 2>&1; then echo ok; return 0; fi
    fi
  done <<EOF
$(request_strings "$1" || true)
EOF
  echo "none"
}

finished() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$1" --query status --output text)" != "RUNNING" ]; }
queue_has() { aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --wait-time-seconds 1 \
  --visibility-timeout 0 --query 'Messages[].Body' --output text | grep -q "$2"; }

tag="$(date +%s)"

# Approval path
po_a="PO-$tag-A"
ex_a="$(start_po "$po_a")"
if [ "$(answer "$po_a" success)" != "ok" ]; then
  echo "The request for $po_a reached brightline-approvals, but none of its values is a usable task token: the manager's callback was refused."
  exit 1
fi
if ! wait_for "approval to finish" 25 finished "$ex_a"; then echo "The approved execution never completed."; exit 1; fi
st="$(aws_local stepfunctions describe-execution --execution-arn "$ex_a" --query status --output text)"
if [ "$st" != "SUCCEEDED" ]; then
  echo "After approval the execution ended as $st: $(aws_local stepfunctions describe-execution --execution-arn "$ex_a" --query '[error,cause]' --output text | cut -c1-240)"
  exit 1
fi
queue_has "$issued" "$po_a" || { echo "$po_a was approved, but no order with its poId arrived on brightline-issued."; exit 1; }

# Rejection path
po_b="PO-$tag-B"
ex_b="$(start_po "$po_b")"
if [ "$(answer "$po_b" failure)" != "ok" ]; then
  echo "Could not reject $po_b: no usable task token on its request."
  exit 1
fi
if ! wait_for "rejection to finish" 25 finished "$ex_b"; then echo "The rejected execution never completed."; exit 1; fi
st="$(aws_local stepfunctions describe-execution --execution-arn "$ex_b" --query status --output text)"
if [ "$st" != "SUCCEEDED" ]; then
  echo "A rejected order ended as $st. Rejection is a normal business outcome: handle it and finish the execution cleanly."
  exit 1
fi
if ! queue_has "$notices" "$po_b" || ! queue_has "$notices" "over budget"; then
  echo "The requester was not told about the rejection: brightline-requester-notices needs a message with the poId and the cause."
  exit 1
fi
if queue_has "$issued" "$po_b"; then
  echo "A rejected order was issued anyway."
  exit 1
fi

echo "Approvals call back and issue the order; rejections notify the requester with the reason and issue nothing."
