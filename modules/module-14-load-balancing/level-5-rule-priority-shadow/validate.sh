#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names corallo-alb --query 'LoadBalancers[0].[LoadBalancerArn,DNSName]' --output text 2>/dev/null || true)
if [ -z "$LB" ] || [ "$LB" = "None" ]; then
  echo "corallo-alb no longer exists."
  exit 1
fi
DNS=$(printf '%s' "$LB" | awk '{print $2}')

CTR="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || CTR="awsmissions-floci-${AWSMISSIONS_PORT}"
fetch() {
  docker exec "$CTR" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" "$2" >&3; cat <&3' _ "$1" "$DNS" 2>/dev/null | tr -d '\r'
}
code_of() { printf '%s' "$1" | head -1 | awk '{print $2}'; }
body_of() { printf '%s' "$1" | sed '1,/^$/d'; }

shop_ready() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$(aws_local elbv2 describe-target-groups --names "$1" --query 'TargetGroups[0].TargetGroupArn' --output text)" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 1 ]
}
for g in corallo-shop corallo-api; do
  wait_for "$g to have a healthy target" 40 shop_ready "$g" || { echo "$g has no healthy target. Do not touch the target groups, only the listener rules."; exit 1; }
done

admin=$(fetch /api/admin/users)
if [ "$(code_of "$admin")" != "403" ]; then
  echo "GET /api/admin/users answers HTTP $(code_of "$admin") (\"$(body_of "$admin" | head -c 60)\"), not 403. Which listener rule actually wins for that path?"
  exit 1
fi
admin2=$(fetch /api/admin/export.csv)
[ "$(code_of "$admin2")" = "403" ] || { echo "GET /api/admin/export.csv is not blocked (HTTP $(code_of "$admin2"))."; exit 1; }

api=$(fetch /api/orders/42)
if [ "$(code_of "$api")" != "200" ] || ! body_of "$api" | grep -q "Corallo API"; then
  echo "GET /api/orders/42 no longer reaches the API fleet (HTTP $(code_of "$api"): \"$(body_of "$api" | head -c 60)\"). Blocking admin must not break the normal API."
  exit 1
fi
shop=$(fetch /products/espresso)
if [ "$(code_of "$shop")" != "200" ] || ! body_of "$shop" | grep -q "Corallo shop front end"; then
  echo "GET /products/espresso no longer reaches the shop front end (HTTP $(code_of "$shop"))."
  exit 1
fi
echo "/api/admin/* is blocked with 403, /api/* reaches the API fleet, everything else reaches the shop."
