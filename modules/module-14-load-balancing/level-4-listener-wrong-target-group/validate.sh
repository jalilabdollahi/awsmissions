#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

DNS=$(aws_local elbv2 describe-load-balancers --names maplewood-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
if [ -z "$DNS" ] || [ "$DNS" = "None" ]; then
  echo "maplewood-alb no longer exists. Repair it instead of deleting it."
  exit 1
fi
for tg in portal-prod portal-staging; do
  if ! aws_local elbv2 describe-target-groups --names "$tg" >/dev/null 2>&1; then
    echo "The target group $tg has been deleted. Both groups are needed: production for members, staging for testers."
    exit 1
  fi
done
STAGE_TG=$(aws_local elbv2 describe-target-groups --names portal-staging --query 'TargetGroups[0].TargetGroupArn' --output text)
PROD_TG=$(aws_local elbv2 describe-target-groups --names portal-prod --query 'TargetGroups[0].TargetGroupArn' --output text)
for g in "$PROD_TG" "$STAGE_TG"; do
  if [ -z "$(aws_local elbv2 describe-target-health --target-group-arn "$g" --query 'TargetHealthDescriptions[].Target.Id' --output text)" ]; then
    echo "A target group lost its instance. Leave the registrations alone: both fleets were healthy."
    exit 1
  fi
done

BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
visit() {
  docker exec "$BOX" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" 2>/dev/null | tr -d '\r'
}

prod_ready() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$PROD_TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 1 ]
}
wait_for "the production target to be healthy" 40 prod_ready || { echo "portal-prod has no healthy target yet; give it a few seconds."; exit 1; }

page=$(visit | tail -1)
case "$page" in
  *STAGING*) echo "Members still land on the staging build: \"$page\". Check where the listener's default action sends requests."; exit 1 ;;
  *"Maplewood Online Banking"*) ;;
  *) echo "Unexpected answer from maplewood-alb: \"$page\" ($(visit | head -1))"; exit 1 ;;
esac

# Every request, not just the first one, must land on production.
for i in 1 2 3 4 5 6; do
  case "$(visit | tail -1)" in
    *"Maplewood Online Banking"*) ;;
    *) echo "Some requests still reach the wrong fleet (request $i)."; exit 1 ;;
  esac
done
echo "maplewood-alb serves the production portal, and the staging group is still available for testers."
