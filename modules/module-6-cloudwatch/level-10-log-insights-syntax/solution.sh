#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("dashboard.json"))
props = doc["widgets"][0]["properties"]
props["query"] = props["query"].replace("/rivergate/payment'", "/rivergate/payments'").replace("Level =", "level =")
json.dump(doc, open("dashboard.json", "w"), indent=2)
PY
aws_local cloudwatch put-dashboard --dashboard-name rivergate-payments --dashboard-body file://dashboard.json
