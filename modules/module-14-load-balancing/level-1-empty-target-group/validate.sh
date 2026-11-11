#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB_ARN=$(aws_local elbv2 describe-load-balancers --names pageturn-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [ -z "$LB_ARN" ] || [ "$LB_ARN" = "None" ]; then
  echo "The load balancer pageturn-alb is gone. Fix the existing one instead of deleting it."
  exit 1
fi
DNS=$(aws_local elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" --query 'LoadBalancers[0].DNSName' --output text)
TG=$(aws_local elbv2 describe-target-groups --names pageturn-web --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "The target group pageturn-web is gone."
  exit 1
fi

INSTANCE=$(aws_local ec2 describe-instances \
  --filters "Name=tag:Name,Values=pageturn-web-1" "Name=instance-state-name,Values=running,pending" \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
if [ -z "$INSTANCE" ] || [ "$INSTANCE" = "None" ]; then
  echo "The web server pageturn-web-1 is not running any more. It was fine: the problem is on the load balancer side."
  exit 1
fi

CONTAINER="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || CONTAINER="awsmissions-floci-${AWSMISSIONS_PORT}"
visit() {
  docker exec "$CONTAINER" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" 2>/dev/null | tr -d '\r'
}

registered=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
  --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE'].Target.Id" --output text)
if [ -z "$registered" ]; then
  echo "A visit to the storefront still fails: $(visit | head -1). The target group pageturn-web has no target that points at $INSTANCE."
  exit 1
fi

is_healthy() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE'].TargetHealth.State | [0]" --output text)" = "healthy" ]
}
if ! wait_for "pageturn-web-1 to become healthy" 45 is_healthy; then
  state=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE'].[Target.Port,TargetHealth.State,TargetHealth.Reason]" --output text)
  echo "$INSTANCE is registered but not healthy yet (port / state / reason: $state)."
  exit 1
fi

response=$(visit)
status=$(printf '%s' "$response" | head -1 | awk '{print $2}')
if [ "$status" != "200" ]; then
  echo "The target is healthy, but a visit to http://pageturn-alb/ still returns HTTP ${status:-no response}."
  exit 1
fi
if ! printf '%s' "$response" | grep -q "Pageturn Books storefront"; then
  echo "The load balancer answers 200, but not with the storefront page."
  exit 1
fi
echo "Visitors reach the Pageturn Books storefront through pageturn-alb, served by $INSTANCE."
