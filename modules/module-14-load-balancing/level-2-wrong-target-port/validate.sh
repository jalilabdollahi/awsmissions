#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

DNS=$(aws_local elbv2 describe-load-balancers --names tidewater-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
TG=$(aws_local elbv2 describe-target-groups --names tracking-api --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$DNS" ] || [ "$DNS" = "None" ] || [ -z "$TG" ] || [ "$TG" = "None" ]; then
  echo "tidewater-alb or the target group tracking-api no longer exists. Both were fine; repair, do not rebuild."
  exit 1
fi
INSTANCE=$(aws_local ec2 describe-instances --filters "Name=tag:Name,Values=tracking-api-1" \
  "Name=instance-state-name,Values=running,pending" --query 'Reservations[0].Instances[0].InstanceId' --output text)
if [ -z "$INSTANCE" ] || [ "$INSTANCE" = "None" ]; then
  echo "The instance tracking-api-1 is not running. It was healthy; the load balancer wiring is the problem."
  exit 1
fi

NAME="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || NAME="awsmissions-floci-${AWSMISSIONS_PORT}"
get_root() {
  docker exec "$NAME" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" 2>/dev/null | tr -d '\r'
}

summary() {
  aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query 'TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]' --output text | tr '\t\n' ' ;'
}
states_now() {
  aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query 'TargetHealthDescriptions[].TargetHealth.State' --output text
}
# Wait until everything is healthy; bail out early when a target has been unhealthy for 12 polls in a row.
tries=0; stuck=0
while [ "$tries" -lt 45 ]; do
  states=$(states_now)
  if [ -n "$states" ] && [ "$states" = "$(printf 'healthy\t%.0s' $states | sed 's/\t$//')" ]; then break; fi
  case " $states " in *" unhealthy "*) stuck=$((stuck + 1)) ;; *) stuck=0 ;; esac
  [ "$stuck" -ge 12 ] && break
  sleep 1; tries=$((tries + 1))
done
states=$(states_now)
if [ -z "$states" ]; then
  echo "tracking-api has no registered targets at all."
  exit 1
fi
for s in $states; do
  if [ "$s" != "healthy" ]; then
    echo "Not every registered target is healthy (id port state): $(summary)"
    exit 1
  fi
done

on_app_port=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
  --query "TargetHealthDescriptions[?Target.Id=='$INSTANCE' && Target.Port==\`8080\`].Target.Id" --output text)
if [ -z "$on_app_port" ]; then
  echo "Targets are healthy, but $INSTANCE is not registered on the port the tracking API listens on (8080)."
  exit 1
fi

response=$(get_root)
if ! printf '%s' "$response" | head -1 | grep -q " 200 "; then
  echo "The target group looks healthy but tidewater-alb answers: $(printf '%s' "$response" | head -1)"
  exit 1
fi
printf '%s' "$response" | grep -q "Tidewater tracking API" || { echo "tidewater-alb answers 200 but not with the tracking API."; exit 1; }
echo "tidewater-alb now reaches the tracking API on $INSTANCE:8080 and every target is healthy."
