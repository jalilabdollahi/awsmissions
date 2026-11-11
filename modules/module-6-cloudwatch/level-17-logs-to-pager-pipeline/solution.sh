#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
f = json.load(open("filter.json"))
f["filterPattern"] = '"ERROR"'
json.dump(f, open("filter.json", "w"), indent=2)
a = json.load(open("alarm.json"))
a["Namespace"] = "Talon/Orders"
json.dump(a, open("alarm.json", "w"), indent=2)
PY
aws_local logs put-metric-filter --cli-input-json file://filter.json
aws_local cloudwatch put-metric-alarm --cli-input-json file://alarm.json
