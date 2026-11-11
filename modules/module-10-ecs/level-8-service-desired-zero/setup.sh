#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cat > /tmp/awsm-sundial-$$.json <<'JSON'
{
  "family": "sundial-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{
    "name": "api",
    "image": "nginx:alpine",
    "essential": true,
    "portMappings": [{"containerPort": 80}]
  }]
}
JSON
aws_local ecs create-cluster --cluster-name sundial >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-sundial-$$.json" >/dev/null
rm -f /tmp/awsm-sundial-$$.json
aws_local ecs create-service --cluster sundial --service-name sundial-api --task-definition sundial-api:1 \
  --desired-count 2 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a,subnet-default-us-east-1-b],assignPublicIp=ENABLED}" >/dev/null
aws_local ecs update-service --cluster sundial --service sundial-api --desired-count 0 >/dev/null
echo "sundial-api is ACTIVE with desiredCount 0."
