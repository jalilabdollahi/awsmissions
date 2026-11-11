#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

cat > /tmp/awsm-tp1-$$.json <<'JSON'
{
  "family": "tidepool-web",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{"name": "web", "image": "nginx:alpine", "essential": true,
    "portMappings": [{"containerPort": 80}],
    "environment": [{"name": "RELEASE", "value": "2025.11.07"}]}]
}
JSON
cat > /tmp/awsm-tp2-$$.json <<'JSON'
{
  "family": "tidepool-web",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{"name": "web", "image": "alpine:3.21", "essential": true,
    "command": ["sh", "-c", "echo running migration 0042; echo FATAL migration 0042 failed: column already exists; exit 3"],
    "environment": [{"name": "RELEASE", "value": "2025.11.14"}]}]
}
JSON
aws_local ecs create-cluster --cluster-name tidepool >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-tp1-$$.json" >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-tp2-$$.json" >/dev/null
rm -f /tmp/awsm-tp1-$$.json /tmp/awsm-tp2-$$.json
aws_local ecs create-service --cluster tidepool --service-name tidepool-web --task-definition tidepool-web:2 --desired-count 2 \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a,subnet-default-us-east-1-c],assignPublicIp=ENABLED}" \
  --deployment-configuration 'deploymentCircuitBreaker={enable=false,rollback=false},maximumPercent=200,minimumHealthyPercent=100' >/dev/null
echo "tidepool-web runs revision 2, which crashes on start-up."
