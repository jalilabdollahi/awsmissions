#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names corallo-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB" --query 'Listeners[0].ListenerArn' --output text)
api_rule=$(aws_local elbv2 describe-rules --listener-arn "$LISTENER" \
  --query "Rules[?Priority=='10'].RuleArn | [0]" --output text)
admin_rule=$(aws_local elbv2 describe-rules --listener-arn "$LISTENER" \
  --query "Rules[?Priority=='20'].RuleArn | [0]" --output text)
aws_local elbv2 set-rule-priorities --rule-priorities "RuleArn=$admin_rule,Priority=5" "RuleArn=$api_rule,Priority=10"
