#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("alarm.json"))
doc["ComparisonOperator"] = "LessThanThreshold"
json.dump(doc, open("alarm.json", "w"), indent=2)
PY
aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
