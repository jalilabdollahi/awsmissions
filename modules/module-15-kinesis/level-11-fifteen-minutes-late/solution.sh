#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Shorter interval, and compress what is written.
jq '.BufferingHints.IntervalInSeconds = 20 | . + {CompressionFormat: "GZIP"}' buffering.json > buffering.new
mv buffering.new buffering.json

current="$(aws_local firehose describe-delivery-stream --delivery-stream-name fraud-signals-to-s3 --output json)"
aws_local firehose update-destination --delivery-stream-name fraud-signals-to-s3 \
  --current-delivery-stream-version-id "$(printf '%s' "$current" | jq -r '.DeliveryStreamDescription.VersionId')" \
  --destination-id "$(printf '%s' "$current" | jq -r '.DeliveryStreamDescription.Destinations[0].DestinationId')" \
  --extended-s3-destination-update file://buffering.json
