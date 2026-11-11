#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group=$(aws_local elbv2 describe-target-groups --names fathomly-api \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# The deep check needs ~7s: give it 10s, and keep the interval above the timeout.
aws_local elbv2 modify-target-group --target-group-arn "$group" \
  --health-check-timeout-seconds 10 \
  --health-check-interval-seconds 20 \
  --unhealthy-threshold-count 3
