#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names invoice-tg --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "The target group invoice-tg is gone. It was correct; fix the ECS side."
  exit 1
fi
PORT=$(aws_local elbv2 describe-target-groups --target-group-arns "$TG" --query 'TargetGroups[0].Port' --output text)
SVC_PORT=$(aws_local ecs describe-services --cluster invoicely --services invoice-api --query 'services[0].loadBalancers[0].containerPort' --output text)
if [ "$SVC_PORT" != "$PORT" ]; then
  echo "The ECS service still registers container port $SVC_PORT with a target group that expects $PORT."
  exit 1
fi
TD=$(aws_local ecs describe-services --cluster invoicely --services invoice-api --query 'services[0].taskDefinition' --output text)
DECL=$(aws_local ecs describe-task-definition --task-definition "$TD" --query 'taskDefinition.containerDefinitions[0].portMappings[0].containerPort' --output text)
if [ "$DECL" != "$PORT" ]; then
  echo "The running task definition ($TD) declares container port $DECL, which does not match the application's port."
  exit 1
fi

healthy() {
  aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "TargetHealthDescriptions[?TargetHealth.State=='healthy' && Target.Port==\`$PORT\`].Target.Id" --output text | grep -q .
}
if ! wait_for "a healthy invoice-tg target" 60 healthy; then
  echo "Port mappings match, but invoice-tg still has no healthy target: $(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]' --output text | tr '\n' ';')"
  exit 1
fi
echo "invoice-api is registered on port $PORT and invoice-tg reports a healthy target."
