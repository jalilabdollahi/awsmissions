#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

if ! aws_local dynamodb describe-table --table-name harvest-orders >/dev/null 2>&1; then
  echo "harvest-orders still does not exist. Check the exact table name (list-tables) - a similarly named table is not the same table."
  exit 1
fi

# Behaviour: write three orders for one farm out of order, then read them back.
for entry in "300:basil" "100:kale" "200:leeks"; do
  ts="${entry%%:*}"; what="${entry##*:}"
  if ! out="$(aws_local dynamodb put-item --table-name harvest-orders \
      --item "{\"farmId\":{\"S\":\"farm-check\"},\"orderedAt\":{\"N\":\"$ts\"},\"product\":{\"S\":\"$what\"}}" 2>&1)"; then
    echo "The ingest service cannot write an order: $(printf '%s' "$out" | tail -1)"
    echo "Orders are keyed by farmId (string) and orderedAt (number)."
    exit 1
  fi
done

# Two orders with the same farm and the same timestamp are the same item; a
# different farm at the same timestamp must be a separate item.
aws_local dynamodb put-item --table-name harvest-orders \
  --item '{"farmId":{"S":"farm-other"},"orderedAt":{"N":"100"},"product":{"S":"plums"}}' >/dev/null

if ! out="$(aws_local dynamodb query --table-name harvest-orders \
    --key-condition-expression 'farmId = :f AND orderedAt BETWEEN :a AND :b' \
    --expression-attribute-values '{":f":{"S":"farm-check"},":a":{"N":"0"},":b":{"N":"250"}}' \
    --query 'Items[].product.S' --output text 2>&1)"; then
  echo "Reading a farm's orders by time range failed: $(printf '%s' "$out" | tail -1)"
  echo "The table needs a sort key to support a range on orderedAt."
  exit 1
fi
if [ "$out" != "$(printf 'kale\tleeks')" ]; then
  echo "Range query for orderedAt 0..250 returned [$out] instead of [kale leeks]."
  exit 1
fi

newest="$(aws_local dynamodb query --table-name harvest-orders \
  --key-condition-expression 'farmId = :f' \
  --expression-attribute-values '{":f":{"S":"farm-check"}}' \
  --no-scan-index-forward --limit 1 --query 'Items[0].product.S' --output text)"
if [ "$newest" != "basil" ]; then
  echo "Newest-first query returned [$newest]; expected basil (orderedAt 300)."
  exit 1
fi

mode="$(aws_local dynamodb describe-table --table-name harvest-orders \
  --query 'Table.BillingModeSummary.BillingMode' --output text)"
if [ "$mode" != "PAY_PER_REQUEST" ]; then
  [ "$mode" = "None" ] && mode=PROVISIONED
  echo "harvest-orders works, but it is not on-demand (billing mode: $mode). Order volume is unpredictable."
  exit 1
fi

aws_local dynamodb delete-item --table-name harvest-orders --key '{"farmId":{"S":"farm-check"},"orderedAt":{"N":"100"}}' >/dev/null
aws_local dynamodb delete-item --table-name harvest-orders --key '{"farmId":{"S":"farm-check"},"orderedAt":{"N":"200"}}' >/dev/null
aws_local dynamodb delete-item --table-name harvest-orders --key '{"farmId":{"S":"farm-check"},"orderedAt":{"N":"300"}}' >/dev/null
aws_local dynamodb delete-item --table-name harvest-orders --key '{"farmId":{"S":"farm-other"},"orderedAt":{"N":"100"}}' >/dev/null
echo "harvest-orders accepts orders and serves them back per farm in time order. Ingest is flowing."
