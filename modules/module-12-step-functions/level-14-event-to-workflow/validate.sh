#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FLOW="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:cedarpoint-fulfilment"
tag="$(date +%s)"
good="CP-$tag-A"
cancelled="CP-$tag-B"
foreign="CP-$tag-C"

put_event() { # source detail-type detail
  aws_local events put-events --entries \
    "[{\"Source\":\"$1\",\"DetailType\":\"$2\",\"Detail\":$(printf '%s' "$3" | jq -Rs .)}]" >/dev/null
}

put_event cedarpoint.shop OrderPlaced "{\"orderId\":\"$good\",\"items\":[{\"sku\":\"MUG-RED\",\"qty\":4},{\"sku\":\"MUG-BLUE\",\"qty\":3}]}"
put_event cedarpoint.shop OrderCancelled "{\"orderId\":\"$cancelled\",\"items\":[{\"sku\":\"MUG-RED\",\"qty\":1}]}"
put_event partner.marketplace OrderPlaced "{\"orderId\":\"$foreign\",\"items\":[{\"sku\":\"MUG-RED\",\"qty\":1}]}"

# Executions of any workflow, with their input, that mention a given order.
executions_for() { # state machine name, order id -> "<status>" lines
  local sm="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:$1" arn
  aws_local stepfunctions list-executions --state-machine-arn "$sm" --query 'executions[].executionArn' --output text | tr '\t' '\n' | while read -r arn; do
    [ -n "$arn" ] || continue
    if aws_local stepfunctions describe-execution --execution-arn "$arn" --query input --output text | grep -q "$2"; then
      aws_local stepfunctions describe-execution --execution-arn "$arn" --query status --output text
    fi
  done
}
find_flow_run() {
  local n
  n="$(executions_for cedarpoint-fulfilment "$good" | grep -vc RUNNING || true)"
  [ "${n:-0}" -ge 1 ]
}
item_exists() {
  aws_local dynamodb get-item --table-name cedarpoint-fulfilments --key "{\"orderId\":{\"S\":\"$good\"}}" \
    --query 'Item.orderId.S' --output text 2>/dev/null | grep -q "$good"
}

legacy="$(executions_for cedarpoint-fulfilment-legacy "$good" | head -1 || true)"

if ! wait_for "the event to start cedarpoint-fulfilment" 20 find_flow_run; then
  if [ -n "$legacy" ]; then
    echo "The event is picked up, but by cedarpoint-fulfilment-legacy, the retired workflow. It is not the one that allocates stock."
  elif [ -z "$(aws_local events list-targets-by-rule --rule cedarpoint-order-placed --query 'Targets[0].Arn' --output text 2>/dev/null | grep -v None || true)" ]; then
    echo "The rule has no target any more. Fix its target instead of removing it."
  else
    echo "A real OrderPlaced event from cedarpoint.shop did not start any execution of cedarpoint-fulfilment. Check whether the rule even matches the event."
  fi
  exit 1
fi

status="$(executions_for cedarpoint-fulfilment "$good" | head -1)"
if [ "$status" != "SUCCEEDED" ]; then
  arn="$(aws_local stepfunctions list-executions --state-machine-arn "$FLOW" --query 'executions[0].executionArn' --output text)"
  echo "The event started cedarpoint-fulfilment, but the execution ended as $status."
  echo "Reason: $(aws_local stepfunctions describe-execution --execution-arn "$arn" --query '[error,cause]' --output text | cut -c1-260)"
  exit 1
fi

if ! wait_for "the fulfilment row" 10 item_exists; then
  echo "The execution succeeded but no row for $good appeared in cedarpoint-fulfilments."
  exit 1
fi
row="$(aws_local dynamodb get-item --table-name cedarpoint-fulfilments --key "{\"orderId\":{\"S\":\"$good\"}}" --output json)"
if [ "$(printf '%s' "$row" | jq -r '.Item.warehouse.S // ""')" != "WH-EAST" ] || [ "$(printf '%s' "$row" | jq -r '.Item.status.S // ""')" != "ALLOCATED" ]; then
  echo "The fulfilment row is wrong (expected 7 units to be allocated to WH-EAST): $(printf '%s' "$row" | jq -c .Item)"
  exit 1
fi

# The rule must stay selective.
sleep 2
if [ -n "$(executions_for cedarpoint-fulfilment "$cancelled")" ] || [ -n "$(executions_for cedarpoint-fulfilment-legacy "$cancelled")" ]; then
  echo "An OrderCancelled event started a workflow. The rule must only match OrderPlaced."
  exit 1
fi
if [ -n "$(executions_for cedarpoint-fulfilment "$foreign")" ] || [ -n "$(executions_for cedarpoint-fulfilment-legacy "$foreign")" ]; then
  echo "An event from partner.marketplace started a workflow. The rule must only match source cedarpoint.shop."
  exit 1
fi

echo "OrderPlaced from cedarpoint.shop now becomes a fulfilment row, and nothing else triggers the workflow."
