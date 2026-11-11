#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TOPIC_ARN="arn:aws:sns:us-east-1:${ACCOUNT_ID}:meridian-oncall" python3 - <<'PY'
import json, os
doc = json.load(open("alarm.json"))
doc["AlarmName"] = "checkout-p99-latency-high"
doc["Threshold"] = 800
doc["ComparisonOperator"] = "GreaterThanThreshold"
doc["AlarmActions"] = [os.environ["TOPIC_ARN"]]
json.dump(doc, open("alarm.json", "w"), indent=2)
PY

aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
