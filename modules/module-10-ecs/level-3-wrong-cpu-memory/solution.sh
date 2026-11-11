#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("task-definition.json"))
doc["cpu"], doc["memory"] = "512", "2048"
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
aws_local ecs register-task-definition --cli-input-json file://task-definition.json >/dev/null
