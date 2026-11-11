#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("task-definition.json"))
doc["containerDefinitions"][0]["environment"].append({"name": "APP_MODE", "value": "worker"})
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
REV=$(aws_local ecs register-task-definition --cli-input-json file://task-definition.json --query taskDefinition.revision --output text)
aws_local ecs update-service --cluster pulse --service pulse-ingest --task-definition "pulse-ingest:$REV" >/dev/null
