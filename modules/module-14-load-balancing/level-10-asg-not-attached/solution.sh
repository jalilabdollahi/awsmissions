#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names orbit-dispatch --query 'TargetGroups[0].TargetGroupArn' --output text)
aws_local autoscaling attach-load-balancer-target-groups --auto-scaling-group-name orbit-dispatch-asg \
  --target-group-arns "$TG"
