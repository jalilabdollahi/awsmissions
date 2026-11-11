#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/ns-intake-role"
Q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/ns-order-queue"
bad=0
echo "Order pipeline triage (INC-8830)"

for res in "lambda get-function --function-name ns-order-intake" "lambda get-function --function-name ns-order-writer" "sqs get-queue-url --queue-name ns-order-queue" "dynamodb describe-table --table-name ns-orders"; do
  # shellcheck disable=SC2086
  if ! aws_local $res >/dev/null 2>&1; then echo "Part of the pipeline was deleted (aws $res). Fix, don't rebuild."; exit 1; fi
done
API="$(aws_local apigateway get-rest-apis --query "items[?name=='ns-orders-api'].id | [0]" --output text 2>/dev/null || true)"
if [ -z "$API" ] || [ "$API" = "None" ]; then echo "ns-orders-api is gone."; exit 1; fi
if [ "$(aws_local dynamodb scan --table-name ns-orders --output json | jq '[.Items[] | select(.sku.S == "mug-red")] | length')" -lt 1 ]; then
  echo "DATA LOSS: the ledger entry o-legacy-1 (mug-red) is no longer in ns-orders."
  exit 1
fi

# Guardrail: intake may only send to its own queue.
rc=0
aws_as_role "$ROLE_ARN" ns-oncall "" sqs send-message --queue-url "$AWS_ENDPOINT_URL/${ACCOUNT_ID}/ns-payments-queue" --message-body '{"probe":true}' >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then echo "ns-oncall cannot assume ns-intake-role any more; leave the trust policy."; exit 1; fi
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: the intake role can send to ns-payments-queue, which belongs to the payments team. Scope it to ns-order-queue."
  exit 1
fi

# Stage 1: intake function configuration.
qurl="$(aws_local lambda get-function-configuration --function-name ns-order-intake --query 'Environment.Variables.QUEUE_URL' --output text 2>/dev/null || echo None)"
qname="${qurl##*/}"
if [ "$qurl" != "None" ] && aws_local sqs get-queue-url --queue-name "$qname" >/dev/null 2>&1 && [ "$qname" = "ns-order-queue" ]; then
  echo "[ok]    stage 1  intake targets the order queue"
else
  echo "[FAULT] stage 1  the intake function is configured to send to '${qname}', which is not the order queue"
  bad=$((bad + 1))
fi

# Stage 2: intake role may send to the queue.
if aws_as_role "$ROLE_ARN" ns-oncall "" sqs send-message --queue-url "$Q" --message-body '{"probe":true}' >/dev/null 2>&1; then
  echo "[ok]    stage 2  the intake role can enqueue orders"
else
  echo "[FAULT] stage 2  the intake role cannot send to ns-order-queue"
  bad=$((bad + 1))
fi

# Stage 3: is the writer allowed to run?
conc="$(aws_local lambda get-function-concurrency --function-name ns-order-writer --query ReservedConcurrentExecutions --output text 2>/dev/null || echo None)"
if [ "$conc" = "0" ]; then
  echo "[FAULT] stage 3  the writer function is throttled and cannot run"
  bad=$((bad + 1))
else
  echo "[ok]    stage 3  the writer function is allowed to run"
fi

# Stage 4: can the writer's record actually be stored? (only testable when it can run)
if [ "$conc" = "0" ]; then
  echo "[WAIT]  stage 4  the table cannot be tested end to end while the writer is throttled"
  bad=$((bad + 1))
else
  out="$(mktemp)"
  pid="schema-probe-$(date +%s)"
  aws_local lambda invoke --function-name ns-order-writer --cli-binary-format raw-in-base64-out \
    --payload "{\"Records\":[{\"messageId\":\"m1\",\"body\":\"{\\\"orderId\\\":\\\"$pid\\\",\\\"sku\\\":\\\"probe-sku\\\"}\"}]}" "$out" >/dev/null 2>&1 || true
  emsg="$(jq -r '.errorMessage // empty' "$out" 2>/dev/null || true)"
  rm -f "$out"
  # remove the probe row (key attribute name depends on the table's schema)
  ks="$(aws_local dynamodb describe-table --table-name ns-orders --query 'Table.KeySchema[0].AttributeName' --output text)"
  aws_local dynamodb delete-item --table-name ns-orders --key "{\"$ks\":{\"S\":\"$pid\"}}" >/dev/null 2>&1 || true
  if [ -n "$emsg" ]; then
    echo "[FAULT] stage 4  the writer fails to store an order: $(printf '%s' "$emsg" | cut -c1-120)"
    bad=$((bad + 1))
  else
    echo "[ok]    stage 4  the writer can store an order"
  fi
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad stage(s) still broken. No live order sent yet."
  exit 1
fi

# Live order through the real front door.
oid="o-live-$(date +%s)"
code="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' \
  -d "{\"orderId\":\"$oid\",\"sku\":\"jacket-green\"}" "$AWS_ENDPOINT_URL/restapis/$API/v1/_user_request_/orders" || true)"
if [ "$code" != "202" ]; then
  echo "POST /v1/orders returned HTTP $code instead of 202."
  exit 1
fi
stored() { aws_local dynamodb scan --table-name ns-orders --output json | jq -e --arg id "$oid" '[.Items[] | select([.[] | .S?] | index($id))] | length > 0' >/dev/null; }
if ! wait_for "order $oid in ns-orders" 60 stored; then
  echo "The order was accepted (HTTP 202) but did not reach ns-orders within 60s."
  exit 1
fi
echo "Order $oid went API -> intake -> queue -> writer -> table; the legacy ledger entry is intact. Orders are being recorded again."
