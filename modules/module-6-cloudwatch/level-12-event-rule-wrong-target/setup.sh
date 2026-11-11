#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name harbor-ingest-prod >/dev/null
aws_local sqs create-queue --queue-name harbor-ingest-staging >/dev/null

aws_local events put-rule --name harbor-shipment-created --state ENABLED \
  --event-pattern '{"source":["harbor.bookings"],"detail-type":["ShipmentCreated"]}' >/dev/null
aws_local events put-targets --cli-input-json "file://$MISSION_DIR/workspace/target.json" >/dev/null

echo "harbor-shipment-created is enabled and delivers to harbor-ingest-staging."
