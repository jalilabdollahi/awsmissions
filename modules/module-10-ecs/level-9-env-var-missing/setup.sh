#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /ecs/pulse-ingest
aws_local ecs create-cluster --cluster-name pulse >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$MISSION_DIR/workspace/task-definition.json" >/dev/null
aws_local ecs create-service --cluster pulse --service-name pulse-ingest --task-definition pulse-ingest:1 \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-c],assignPublicIp=ENABLED}" >/dev/null
echo "pulse-ingest is crash-looping."
