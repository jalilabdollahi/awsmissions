#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("filter.json"))
doc["filterPattern"] = '"ERROR"'
json.dump(doc, open("filter.json", "w"), indent=2)
PY

aws_local logs put-metric-filter --cli-input-json file://filter.json
