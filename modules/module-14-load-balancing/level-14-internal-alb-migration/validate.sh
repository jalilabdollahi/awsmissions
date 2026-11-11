#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. No internal gateway may be left behind.
leftover=$(aws_local elbv2 describe-load-balancers --query "LoadBalancers[?Scheme=='internal'].LoadBalancerName" --output text)
if [ -n "$leftover" ]; then
  echo "The internal load balancer ($leftover) still exists. A scheme cannot be changed; it has to be replaced, not kept alongside."
  exit 1
fi

# 2. Find the replacement: an internet-facing ALB.
NEW=$(aws_local elbv2 describe-load-balancers \
  --query "LoadBalancers[?Scheme=='internet-facing' && Type=='application'].[LoadBalancerArn,DNSName,LoadBalancerName] | [0]" --output text)
if [ -z "$NEW" ] || [ "$NEW" = "None" ]; then
  echo "There is no internet-facing Application Load Balancer yet."
  exit 1
fi
NEW_ARN=$(printf '%s' "$NEW" | awk '{print $1}')
NEW_DNS=$(printf '%s' "$NEW" | awk '{print $2}')
NEW_NAME=$(printf '%s' "$NEW" | awk '{print $3}')

zones=$(aws_local elbv2 describe-load-balancers --load-balancer-arns "$NEW_ARN" \
  --query 'length(LoadBalancers[0].AvailabilityZones)' --output text)
if [ "$zones" -lt 2 ]; then
  echo "$NEW_NAME spans only $zones Availability Zone(s); production traffic needs at least two."
  exit 1
fi
WEB_ARN=$(aws_local elbv2 describe-target-groups --names nimbus-web --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$WEB_ARN" ] || [ "$WEB_ARN" = "None" ]; then echo "The target group nimbus-web was deleted; reuse it."; exit 1; fi
LPORT=$(aws_local elbv2 describe-tags --resource-arns "$WEB_ARN" \
  --query "TagDescriptions[0].Tags[?Key=='listener-port'].Value | [0]" --output text)
if [ -z "$(aws_local elbv2 describe-listeners --load-balancer-arn "$NEW_ARN" --query "Listeners[?Port==\`$LPORT\`].ListenerArn" --output text)" ]; then
  echo "$NEW_NAME has no listener on port $LPORT, the port the old gateway used (clients and firewalls expect that port)."
  exit 1
fi

for g in nimbus-web nimbus-api; do
  arn=$(aws_local elbv2 describe-target-groups --names "$g" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
  if [ -z "$arn" ] || [ "$arn" = "None" ]; then echo "The target group $g was deleted; reuse it."; exit 1; fi
  ready() { [ "$(aws_local elbv2 describe-target-health --target-group-arn "$arn" --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 1 ]; }
  wait_for "$g healthy" 40 ready || { echo "$g has no healthy target."; exit 1; }
done

BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
fetch() {
  docker exec "$BOX" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/"$3"; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' _ "$1" "$2" "$LPORT" 2>/dev/null | tr -d '\r'
}
status_of() { printf '%s' "$1" | head -1 | awk '{print $2}'; }
body_of() { printf '%s' "$1" | sed '1,/^$/d'; }

r=$(fetch / "$NEW_DNS")
if [ "$(status_of "$r")" != "200" ] || ! body_of "$r" | grep -q "Nimbus Notes web app"; then
  echo "$NEW_NAME: GET / should reach the web fleet, got HTTP $(status_of "$r") \"$(body_of "$r" | head -c 50)\"."
  exit 1
fi
r=$(fetch /status "$NEW_DNS")
if [ "$(status_of "$r")" != "200" ] || ! body_of "$r" | grep -q "nimbus gateway: all systems go"; then
  echo "$NEW_NAME: GET /status should be answered by the load balancer itself (\"nimbus gateway: all systems go\"), got HTTP $(status_of "$r") \"$(body_of "$r" | head -c 50)\"."
  exit 1
fi
r=$(fetch / api.nimbusnotes.example)
if [ "$(status_of "$r")" != "200" ] || ! body_of "$r" | grep -q "Nimbus Notes REST API"; then
  echo "Requests for Host: api.nimbusnotes.example do not reach the API fleet (HTTP $(status_of "$r") \"$(body_of "$r" | head -c 50)\")."
  exit 1
fi
r=$(fetch /status api.nimbusnotes.example)
if ! body_of "$r" | grep -q "all systems go"; then
  echo "/status on the API host should also be answered by the load balancer (it was rule number one in the old gateway)."
  exit 1
fi
echo "$NEW_NAME is internet-facing across $zones zones and routes web, API and /status exactly as the old gateway did."
