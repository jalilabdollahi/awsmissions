#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names helix-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
L=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB" --query 'Listeners[0].ListenerArn' --output text)
RULE=$(aws_local elbv2 describe-rules --listener-arn "$L" --query "Rules[?Priority=='10'].RuleArn | [0]" --output text)
aws_local elbv2 modify-rule --rule-arn "$RULE" \
  --conditions '[{"Field":"host-header","Values":["portal.helixpay.example","app.helixpay.example"]}]'
