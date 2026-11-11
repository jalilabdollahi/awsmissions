#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TD_FILE="$(mktemp)"
trap 'rm -f "$TD_FILE"' EXIT
python3 - "$TD_FILE" <<'PY'
import json, sys
spec = {
    "family": "inventory", "networkMode": "awsvpc", "requiresCompatibilities": ["FARGATE"],
    "cpu": "256", "memory": "512",
    "containerDefinitions": [{"name": "inventory", "image": "nginx:alpine", "essential": True,
                              "portMappings": [{"containerPort": 80}]}],
}
json.dump(spec, open(sys.argv[1], "w"))
PY
aws_local ecs create-cluster --cluster-name shop >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$TD_FILE" >/dev/null
SUBNETS="subnet-default-us-east-1-a,subnet-default-us-east-1-b"
aws_local ecs create-service --cluster shop --service-name inventory --task-definition inventory:1 \
  --desired-count 2 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],assignPublicIp=ENABLED}" >/dev/null
echo "inventory runs two tasks, registered nowhere."
