#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=stockroom-bins
n="$(aws_local dynamodb scan --table-name "$T" --select COUNT --query Count --output text 2>/dev/null || echo 0)"
if [ "$n" != "5" ]; then
  echo "Expected the 5 stock records, found $n. The table must not be rebuilt or emptied."
  exit 1
fi

st="$(aws_local dynamodb describe-table --table-name "$T" \
  --query 'Table.GlobalSecondaryIndexes[?IndexName==`sku-index`].IndexStatus' --output text 2>/dev/null || true)"
if [ -z "$st" ] || [ "$st" = "None" ]; then
  echo "There is no index named sku-index right now. The picker app looks for exactly that name."
  exit 1
fi
if [ "$st" != "ACTIVE" ]; then
  echo "sku-index is $st; wait until it is ACTIVE and run check again."
  exit 1
fi

if ! out="$(aws_local dynamodb query --table-name "$T" --index-name sku-index \
    --key-condition-expression 'sku = :s AND qty >= :n' \
    --expression-attribute-values '{":s":{"S":"BOLT-M8"},":n":{"N":"40"}}' \
    --query 'Items[].binId.S' --output text 2>&1)"; then
  echo "The picker query (sku = :s AND qty >= :n) is rejected: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
# Sorted ascending by qty: B-07-2 (45) before A-01-3 (120).
if [ "$out" != "$(printf 'B-07-2\tA-01-3')" ]; then
  echo "Bins for BOLT-M8 with at least 40 units came back as [$out]; expected B-07-2 then A-01-3 (ordered by qty)."
  exit 1
fi

empty="$(aws_local dynamodb query --table-name "$T" --index-name sku-index \
  --key-condition-expression 'sku = :s' --expression-attribute-values '{":s":{"S":"NUT-M8"}}' \
  --query 'Items[0].binId.S' --output text)"
if [ "$empty" != "C-01-1" ]; then
  echo "NUT-M8 should resolve to bin C-01-1 through the index, got [$empty]."
  exit 1
fi
echo "sku-index answers SKU questions again, ordered by quantity. Pickers are moving."
