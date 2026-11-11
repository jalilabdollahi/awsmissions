#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names maplewood-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB" --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)
PROD_TG=$(aws_local elbv2 describe-target-groups --names portal-prod --query 'TargetGroups[0].TargetGroupArn' --output text)
aws_local elbv2 modify-listener --listener-arn "$LISTENER" --default-actions "Type=forward,TargetGroupArn=$PROD_TG"
