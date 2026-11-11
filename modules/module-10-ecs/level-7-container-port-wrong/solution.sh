#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

sed 's/"containerPort": 8080/"containerPort": 3000/' task-definition.json > td.new && mv td.new task-definition.json
REV=$(aws_local ecs register-task-definition --cli-input-json file://task-definition.json --query taskDefinition.revision --output text)
TG=$(aws_local elbv2 describe-target-groups --names invoice-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws_local ecs update-service --cluster invoicely --service invoice-api --task-definition "invoice-api:$REV" \
  --load-balancers "targetGroupArn=$TG,containerName=app,containerPort=3000" >/dev/null
