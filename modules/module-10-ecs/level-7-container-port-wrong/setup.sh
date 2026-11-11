#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 create-target-group --name invoice-tg --protocol HTTP --port 3000 --vpc-id vpc-default-us-east-1 \
  --target-type ip --health-check-path /health --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 --query 'TargetGroups[0].TargetGroupArn' --output text)
aws_local ecs create-cluster --cluster-name invoicely >/dev/null
aws_local ecs register-task-definition --cli-input-json "file://$MISSION_DIR/workspace/task-definition.json" >/dev/null
aws_local ecs create-service --cluster invoicely --service-name invoice-api --task-definition invoice-api:1 \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG,containerName=app,containerPort=8080" >/dev/null
echo "invoice-api registers port 8080 with invoice-tg; the app listens on 3000."
