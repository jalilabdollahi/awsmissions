#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /ecs/checkout-worker
aws_local logs put-retention-policy --log-group-name /ecs/checkout-worker --retention-in-days 14
aws_local ecs create-cluster --cluster-name marigold >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$MISSION_DIR/workspace/task-definition.json" >/dev/null
aws_local ecs create-service --cluster marigold --service-name checkout-worker --task-definition checkout-worker:1 \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a],assignPublicIp=ENABLED}" >/dev/null
echo "checkout-worker runs with the journald driver; /ecs/checkout-worker is empty."
