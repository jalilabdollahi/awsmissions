#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("destination.json"))
doc["BucketARN"] = "arn:aws:s3:::harborview-datalake"
doc["Prefix"] = "clicks/dt=!{timestamp:yyyy-MM-dd}/"
json.dump(doc, open("destination.json", "w"), indent=2)
PY

version="$(aws_local firehose describe-delivery-stream --delivery-stream-name clickstream-to-lake \
  --query DeliveryStreamDescription.VersionId --output text)"
dest="$(aws_local firehose describe-delivery-stream --delivery-stream-name clickstream-to-lake \
  --query 'DeliveryStreamDescription.Destinations[0].DestinationId' --output text)"
aws_local firehose update-destination --delivery-stream-name clickstream-to-lake \
  --current-delivery-stream-version-id "$version" --destination-id "$dest" \
  --extended-s3-destination-update file://destination.json
