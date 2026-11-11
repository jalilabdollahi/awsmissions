#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

orders_group=$(aws_local elbv2 describe-target-groups --names brewline-orders \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
# The API's liveness route is /healthz; "/" is a 404 for this service.
aws_local elbv2 modify-target-group --target-group-arn "$orders_group" \
  --health-check-protocol HTTP --health-check-path /healthz \
  --matcher HttpCode=200
