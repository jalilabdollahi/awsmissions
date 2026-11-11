#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

WEB_TG=$(aws_local elbv2 describe-target-groups --names nimbus-web --query 'TargetGroups[0].TargetGroupArn' --output text)
API_TG=$(aws_local elbv2 describe-target-groups --names nimbus-api --query 'TargetGroups[0].TargetGroupArn' --output text)

OLD_PORT=$(aws_local elbv2 describe-listeners --load-balancer-arn "$(aws_local elbv2 describe-load-balancers --names nimbus-gateway --query 'LoadBalancers[0].LoadBalancerArn' --output text)" --query 'Listeners[0].Port' --output text)

# Retire the internal gateway first (its scheme cannot be changed).
OLD=$(aws_local elbv2 describe-load-balancers --names nimbus-gateway --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 delete-load-balancer --load-balancer-arn "$OLD"

NEW=$(aws_local elbv2 create-load-balancer --name nimbus-gateway-public --scheme internet-facing --type application \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
L=$(aws_local elbv2 create-listener --load-balancer-arn "$NEW" --protocol HTTP --port "$OLD_PORT" \
  --default-actions "Type=forward,TargetGroupArn=$WEB_TG" --query 'Listeners[0].ListenerArn' --output text)
aws_local elbv2 create-rule --listener-arn "$L" --priority 10 \
  --conditions '[{"Field":"path-pattern","Values":["/status"]}]' \
  --actions '[{"Type":"fixed-response","FixedResponseConfig":{"StatusCode":"200","ContentType":"text/plain","MessageBody":"nimbus gateway: all systems go"}}]'
aws_local elbv2 create-rule --listener-arn "$L" --priority 20 \
  --conditions '[{"Field":"host-header","Values":["api.nimbusnotes.example"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$API_TG\"}]"
