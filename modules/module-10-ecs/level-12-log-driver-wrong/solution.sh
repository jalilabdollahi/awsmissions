#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
import json
doc = json.load(open("task-definition.json"))
doc["containerDefinitions"][0]["logConfiguration"] = {
    "logDriver": "awslogs",
    "options": {
        "awslogs-group": "/ecs/checkout-worker",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "worker",
    },
}
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
REV=$(aws_local ecs register-task-definition --cli-input-json file://task-definition.json --query taskDefinition.revision --output text)
aws_local ecs update-service --cluster marigold --service checkout-worker --task-definition "checkout-worker:$REV" >/dev/null
