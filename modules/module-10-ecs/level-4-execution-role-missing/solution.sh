#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET_ARN=$(aws_local secretsmanager describe-secret --secret-id payroll/db-password --query ARN --output text)
aws_local iam create-role --role-name payroll-exec-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam attach-role-policy --role-name payroll-exec-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws_local iam put-role-policy --role-name payroll-exec-role --policy-name read-db-password --policy-document \
  "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"secretsmanager:GetSecretValue\",\"Resource\":\"$SECRET_ARN\"}]}"

python3 - <<'PY'
import json
doc = json.load(open("task-definition.json"))
doc["executionRoleArn"] = "arn:aws:iam::000000000000:role/payroll-exec-role"
json.dump(doc, open("task-definition.json", "w"), indent=2)
PY
REV=$(aws_local ecs register-task-definition --cli-input-json file://task-definition.json --query taskDefinition.revision --output text)
aws_local ecs update-service --cluster payroll --service payroll-api --task-definition "payroll-api:$REV" >/dev/null
