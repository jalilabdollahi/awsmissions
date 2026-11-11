#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. + 2. Register revision 2: working image, correct variable name.
aws_local ecs describe-task-definition --task-definition ledger-web:1 --query taskDefinition > td.json
python3 - <<'PY'
import json
td = json.load(open("td.json"))
c = td["containerDefinitions"][0]
c["image"] = "nginx:alpine"
c["environment"] = [{"name": "DB_HOST", "value": "ledger-db.internal"}]
keep = ["family", "networkMode", "requiresCompatibilities", "cpu", "memory", "executionRoleArn", "containerDefinitions"]
json.dump({k: td[k] for k in keep}, open("td2.json", "w"))
PY
aws_local ecs register-task-definition --cli-input-json file://td2.json >/dev/null

# 3. Point the service at it and scale to two tasks.
aws_local ecs update-service --cluster ledger-prod --service ledger-web --task-definition ledger-web:2 --desired-count 2 >/dev/null
