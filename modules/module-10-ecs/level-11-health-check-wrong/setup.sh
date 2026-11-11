#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 create-target-group --name gateway-tg --protocol HTTP --port 8000 --vpc-id vpc-default-us-east-1 \
  --target-type ip --health-check-path /healthz --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 --query 'TargetGroups[0].TargetGroupArn' --output text)
cat > /tmp/awsm-gateway-$$.json <<'JSON'
{
  "family": "gateway",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "gw",
    "image": "python:3.12-alpine",
    "essential": true,
    "command": ["sh", "-c", "mkdir -p /srv/gw && echo ready > /srv/gw/health && cd /srv/gw && python -m http.server 8000 --bind 0.0.0.0"],
    "portMappings": [{"containerPort": 8000}]
  }]
}
JSON
aws_local ecs create-cluster --cluster-name tidewater >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-gateway-$$.json" >/dev/null
rm -f /tmp/awsm-gateway-$$.json
aws_local ecs create-service --cluster tidewater --service-name gateway --task-definition gateway:1 --desired-count 1 \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-c],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG,containerName=gw,containerPort=8000" >/dev/null
echo "gateway is running; gateway-tg probes /healthz."
