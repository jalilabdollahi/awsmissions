#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

for b in pixelmill-uploads pixelmill-thumbs pixelmill-billing; do aws_local s3 mb "s3://$b" >/dev/null; done
TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws_local iam create-role --role-name pixelmill-exec-role --assume-role-policy-document "$TRUST" >/dev/null
aws_local iam attach-role-policy --role-name pixelmill-exec-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws_local iam create-role --role-name pixelmill-task-role --assume-role-policy-document "$TRUST" >/dev/null
aws_local iam put-role-policy --role-name pixelmill-task-role --policy-name resizer-s3 \
  --policy-document "file://$MISSION_DIR/workspace/task-role-policy.json"

cat > /tmp/awsm-resizer-$$.json <<JSON
{
  "family": "resizer",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/pixelmill-exec-role",
  "taskRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/pixelmill-task-role",
  "containerDefinitions": [{"name": "resizer", "image": "alpine:3.21", "essential": true,
    "command": ["sh", "-c", "echo resizer running; sleep 3600"]}]
}
JSON
aws_local ecs create-cluster --cluster-name pixelmill >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-resizer-$$.json" >/dev/null
rm -f /tmp/awsm-resizer-$$.json
aws_local ecs create-service --cluster pixelmill --service-name resizer --task-definition resizer:1 --desired-count 1 \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-b],assignPublicIp=ENABLED}" >/dev/null
echo "The resizer runs with pixelmill-task-role; its S3 policy uses bucket-level ARNs only."
