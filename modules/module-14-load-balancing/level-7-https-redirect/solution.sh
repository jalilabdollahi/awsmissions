#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names quillstone-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB" --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)
aws_local elbv2 modify-listener --listener-arn "$LISTENER" --default-actions \
  '[{"Type":"redirect","RedirectConfig":{"Protocol":"HTTPS","Port":"443","Host":"#{host}","Path":"/#{path}","Query":"#{query}","StatusCode":"HTTP_301"}}]'
