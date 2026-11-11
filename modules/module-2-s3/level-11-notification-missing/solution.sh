#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
cfg = {
    "QueueConfigurations": [{
        "Id": "pdf-invoices-to-robot",
        "QueueArn": "arn:aws:sqs:us-east-1:000000000000:invoice-intake",
        "Events": ["s3:ObjectCreated:*"],
        "Filter": {"Key": {"FilterRules": [
            {"Name": "prefix", "Value": "inbox/"},
            {"Name": "suffix", "Value": ".pdf"},
        ]}},
    }]
}
json.dump(cfg, open("notification.json", "w"), indent=2)
PY

aws_local s3api put-bucket-notification-configuration --bucket acornpay-invoices \
  --notification-configuration file://notification.json
