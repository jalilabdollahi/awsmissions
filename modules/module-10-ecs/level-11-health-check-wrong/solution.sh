#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names gateway-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws_local elbv2 modify-target-group --target-group-arn "$TG" --health-check-path /health >/dev/null
