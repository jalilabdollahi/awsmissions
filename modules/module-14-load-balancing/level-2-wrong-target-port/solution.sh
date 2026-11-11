#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names tracking-api --query 'TargetGroups[0].TargetGroupArn' --output text)
INSTANCE=$(aws_local ec2 describe-instances --filters "Name=tag:Name,Values=tracking-api-1" \
  "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws_local elbv2 deregister-targets --target-group-arn "$TG" --targets "Id=$INSTANCE,Port=80"
aws_local elbv2 register-targets --target-group-arn "$TG" --targets "Id=$INSTANCE"
