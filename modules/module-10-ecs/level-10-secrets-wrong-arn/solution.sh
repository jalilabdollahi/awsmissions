#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ARN=$(aws_local secretsmanager describe-secret --secret-id cedar/db-credentials --query ARN --output text)
python3 - "$ARN" <<'PY'
import json, sys
doc = json.load(open("task-definition.json"))
for secret in doc["containerDefinitions"][0]["secrets"]:
    key = secret["valueFrom"].rsplit(":", 3)[1]
    secret["valueFrom"] = "%s:%s::" % (sys.argv[1], key)
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
REV=$(aws_local ecs register-task-definition --cli-input-json file://task-definition.json --query taskDefinition.revision --output text)
aws_local ecs update-service --cluster cedar --service ledger-sync --task-definition "ledger-sync:$REV" >/dev/null
