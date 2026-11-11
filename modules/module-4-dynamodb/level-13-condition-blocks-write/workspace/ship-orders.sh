#!/usr/bin/env bash
# Marks the orders reported by the loading dock as shipped.
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"

for id in ord-1042 ord-1043; do
  echo "shipping $id ..."
  aws --endpoint-url "$ENDPOINT" dynamodb update-item \
    --table-name parcelo-orders \
    --key "{\"orderId\":{\"S\":\"$id\"}}" \
    --update-expression "SET #s = :shipped, trackingNo = :trk ADD version :one" \
    --condition-expression "attribute_not_exists(orderId)" \
    --expression-attribute-names '{"#s":"status"}' \
    --expression-attribute-values "{\":shipped\":{\"S\":\"SHIPPED\"},\":trk\":{\"S\":\"TRK-$id-$(date +%s)\"},\":one\":{\"N\":\"1\"}}" \
    || echo "  -> not shipped: $id"
done
