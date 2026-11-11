#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local secretsmanager create-secret --name cedar/db-credentials \
  --secret-string '{"username":"ledger_sync","password":"c3d4r-pr0d-pw"}' >/dev/null
aws_local ecs create-cluster --cluster-name cedar >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$MISSION_DIR/workspace/task-definition.json" >/dev/null
aws_local ecs create-service --cluster cedar --service-name ledger-sync --task-definition ledger-sync:1 \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-b],assignPublicIp=ENABLED}" >/dev/null
echo "ledger-sync tasks fail before the container starts."
