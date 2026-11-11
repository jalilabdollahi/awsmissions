#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

IMAGE=$(aws_local ssm get-parameter --name /hearth/web/approved-image --query Parameter.Value --output text)
python3 - "$IMAGE" <<'PY'
import json, sys
doc = json.load(open("task-definition.json"))
doc["containerDefinitions"][0]["image"] = sys.argv[1]
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
aws_local ecs register-task-definition --cli-input-json file://task-definition.json >/dev/null
bash deploy.sh >/dev/null
