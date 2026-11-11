#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local ssm put-parameter --name /hearth/web/approved-image --type String --value nginx:alpine >/dev/null
aws_local ecs create-cluster --cluster-name hearth >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$MISSION_DIR/workspace/task-definition.json" >/dev/null
# One attempt so there is a stopped task to investigate.
aws_local ecs run-task --cluster hearth --task-definition hearth-web --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-c]}" >/dev/null
echo "hearth-web was launched once and stopped immediately."
