#!/usr/bin/env bash
# Nightly report job: shipments of one region after a timestamp.
# Usage: ./report.sh emea 1767050000     (run it with the credentials of orbit-report-svc)
ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"

aws --endpoint-url "$ENDPOINT" dynamodb scan \
  --table-name orbit-shipments \
  --filter-expression "region = :r AND shippedAt > :t" \
  --expression-attribute-values "{\":r\":{\"S\":\"${1:?region}\"},\":t\":{\"N\":\"${2:?epoch}\"}}" \
  --query 'Items[].shipmentId.S' --output text
