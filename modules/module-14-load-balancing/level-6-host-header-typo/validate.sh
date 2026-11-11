#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

OWN=$(aws_local elbv2 describe-load-balancers --names helix-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
if [ -z "$OWN" ] || [ "$OWN" = "None" ]; then
  echo "helix-alb is gone."
  exit 1
fi

LISTEN=$(aws_local elbv2 describe-listeners --load-balancer-arn "$(aws_local elbv2 describe-load-balancers --names helix-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)" --query 'Listeners[0].Port' --output text)
BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
as_host() {
  docker exec "$BOX" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/"$2"; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$1" "$LISTEN" 2>/dev/null | tr -d '\r' | sed '1,/^$/d'
}

for g in helix-marketing helix-portal; do
  arn=$(aws_local elbv2 describe-target-groups --names "$g" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
  if [ -z "$arn" ] || [ "$arn" = "None" ]; then echo "The target group $g was deleted."; exit 1; fi
  ready() { [ "$(aws_local elbv2 describe-target-health --target-group-arn "$arn" --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 1 ]; }
  wait_for "$g healthy" 40 ready || { echo "$g has no healthy target; do not touch the fleets."; exit 1; }
done

for host in portal.helixpay.example app.helixpay.example; do
  page=$(as_host "$host")
  case "$page" in
    *"customer portal"*) ;;
    "") echo "A request for Host: $host gets no answer at all from helix-alb."; exit 1 ;;
    *) echo "Host: $host is served \"$page\" instead of the customer portal. Compare the hostnames in the listener rule with what customers type."; exit 1 ;;
  esac
done

# The default rule must keep serving the marketing fleet for other hosts.
page=$(as_host "$OWN")
case "$page" in
  *"marketing site"*) ;;
  *) echo "The default route no longer serves the marketing site (got \"$page\")."; exit 1 ;;
esac

# A rule that matches everything would also "work" for the two hosts; make sure it is not a catch-all.
for host in www.helixpay.example helixpay.example; do
  page=$(as_host "$host")
  case "$page" in
    *"customer portal"*) echo "Host: $host also reaches the customer portal. The rule should only match the two portal hostnames."; exit 1 ;;
  esac
done
echo "portal.helixpay.example and app.helixpay.example reach the portal; other hosts still get the marketing site."
