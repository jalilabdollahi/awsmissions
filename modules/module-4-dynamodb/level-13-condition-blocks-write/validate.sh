#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

T=parcelo-orders
get() {
  aws_local dynamodb get-item --table-name "$T" --key "{\"orderId\":{\"S\":\"$1\"}}" \
    --query "Item.[$2]" --output text 2>/dev/null || echo "ERR"
}

shipped="$(get ord-1042 'status.S,version.N')"
if [ "$shipped" != "$(printf 'SHIPPED\t8')" ]; then
  echo "ord-1042 should be SHIPPED at version 8; it is [$shipped]."
  exit 1
fi
trk="$(get ord-1042 'trackingNo.S')"
case "$trk" in
  TRK-*) ;;
  *) echo "ord-1042 is shipped but has no tracking number."; exit 1 ;;
esac
rest="$(get ord-1042 'customerId.S,length(lineItems.L)')"
if [ "$rest" != "$(printf 'cust-318\t2')" ]; then
  echo "ord-1042 lost data while being updated (customerId / lineItems are [$rest])."
  exit 1
fi

old="$(get ord-1043 'status.S,version.N,trackingNo.S')"
if [ "$old" != "$(printf 'SHIPPED\t3\tTRK-OLD-777')" ]; then
  echo "ord-1043 was already shipped and was touched again: [$old]. The guard must still refuse orders that are not PACKED."
  exit 1
fi

# The guard itself must still be doing its job at the table: a stale write is refused.
if aws_local dynamodb update-item --table-name "$T" --key '{"orderId":{"S":"ord-1042"}}' \
    --update-expression 'SET trackingNo = :x' \
    --condition-expression 'version = :stale' \
    --expression-attribute-values '{":x":{"S":"TRK-hijack"},":stale":{"N":"7"}}' >/dev/null 2>&1; then
  echo "A write using a stale version (7) was accepted. Optimistic locking is not working."
  exit 1
fi
echo "ord-1042 shipped exactly once with a version bump; ord-1043 untouched. The guard works as intended."
