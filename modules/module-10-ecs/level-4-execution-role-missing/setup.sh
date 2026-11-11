#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET_ARN=$(aws_local secretsmanager create-secret --name payroll/db-password --secret-string 'hunter2-prod' --query ARN --output text)
aws_local secretsmanager create-secret --name payroll/ceo-notes --secret-string 'not for the API' >/dev/null
aws_local logs create-log-group --log-group-name /ecs/payroll-api
aws_local ecs create-cluster --cluster-name payroll >/dev/null

# Put the real secret ARN into the player's working copy.
python3 - "$WORKDIR/task-definition.json" "$SECRET_ARN" <<'PY'
import sys
path, arn = sys.argv[1:3]
text = open(path).read().replace("__SECRET_ARN__", arn)
open(path, "w").write(text)
PY

aws_local ecs register-task-definition --cli-input-json "file://$WORKDIR/task-definition.json" >/dev/null
aws_local ecs create-service --cluster payroll --service-name payroll-api --task-definition payroll-api:1 \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a],assignPublicIp=ENABLED}" >/dev/null
echo "payroll-api:1 is registered without an execution role."
