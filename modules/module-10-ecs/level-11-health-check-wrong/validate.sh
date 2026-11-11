#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TG=$(aws_local elbv2 describe-target-groups --names gateway-tg --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "gateway-tg no longer exists; it only needs a corrected health check."
  exit 1
fi
HC=$(aws_local elbv2 describe-target-groups --target-group-arns "$TG" --query 'TargetGroups[0].[HealthCheckPath,Matcher.HttpCode]' --output text)
HC_PATH=$(printf '%s' "$HC" | awk '{print $1}')
CODES=$(printf '%s' "$HC" | awk '{print $2}')
if [ "$CODES" != "200" ]; then
  echo "The health check now accepts response codes '$CODES'. Accepting more than 200 hides real failures; keep the matcher strict."
  exit 1
fi
if [ "$HC_PATH" = "/" ]; then
  echo "The health check probes '/', which is not part of the API contract and happens to answer today. Probe the readiness endpoint the service documents."
  exit 1
fi
if [ "$HC_PATH" != "/health" ]; then
  echo "The health check still probes $HC_PATH, which the gateway does not serve (it answers 404)."
  exit 1
fi
healthy() {
  aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "TargetHealthDescriptions[?TargetHealth.State=='healthy'].Target.Id" --output text | grep -q .
}
if ! wait_for "a healthy gateway target" 45 healthy; then
  echo "The health check path is right but no target is healthy yet: $(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[TargetHealth.State,TargetHealth.Reason]' --output text | tr '\n' ';')"
  exit 1
fi
echo "gateway-tg probes /health with success code 200 and its target is healthy."
