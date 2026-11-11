#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Resolve the storefront instance by its Name tag, then the group by name, then join them.
web_id=$(aws_local ec2 describe-instances \
  --filters Name=tag:Name,Values=pageturn-web-1 Name=instance-state-name,Values=running,pending \
  --query 'Reservations[].Instances[].InstanceId' --output text)
group_arn=$(aws_local elbv2 describe-target-groups --names pageturn-web \
  --query 'TargetGroups[].TargetGroupArn' --output text)
echo "registering $web_id into $group_arn"
aws_local elbv2 register-targets --target-group-arn "$group_arn" --targets "Id=${web_id}"
