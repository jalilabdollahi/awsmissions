#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LB=$(aws_local elbv2 describe-load-balancers --names saffron-alb --query 'LoadBalancers[0].[LoadBalancerArn,DNSName]' --output text 2>/dev/null || true)
if [ -z "$LB" ] || [ "$LB" = "None" ]; then echo "saffron-alb is gone."; exit 1; fi
LB_ARN=$(printf '%s' "$LB" | awk '{print $1}')
DNS=$(printf '%s' "$LB" | awk '{print $2}')
BLUE_TG=$(aws_local elbv2 describe-target-groups --names saffron-blue --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
GREEN_TG=$(aws_local elbv2 describe-target-groups --names saffron-green --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -z "$BLUE_TG" ] || [ "$BLUE_TG" = "None" ] || [ -z "$GREEN_TG" ] || [ "$GREEN_TG" = "None" ]; then
  echo "Both target groups (saffron-blue and saffron-green) must still exist."
  exit 1
fi
LISTENER=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --query 'Listeners[?Port==`80`].ListenerArn | [0]' --output text)

weight_of() {
  aws_local elbv2 describe-listeners --listener-arns "$LISTENER" \
    --query "Listeners[0].DefaultActions[0].ForwardConfig.TargetGroups[?TargetGroupArn=='$1'].Weight | [0]" --output text
}
wb=$(weight_of "$BLUE_TG")
wg=$(weight_of "$GREEN_TG")
if [ "$wb" = "None" ] || [ -z "$wb" ]; then
  echo "Blue is no longer part of the listener's forward action. The runbook keeps it attached with weight 0 so rollback is instant."
  exit 1
fi
if [ "$wg" = "None" ] || [ -z "$wg" ] || [ "$wg" -le 0 ]; then
  echo "Green's weight is ${wg:-unset}; it must receive the traffic."
  exit 1
fi
if [ "$wb" -ne 0 ]; then
  echo "Blue still has weight $wb. After cutover blue must stay attached with weight 0."
  exit 1
fi

healthy_in() {
  aws_local elbv2 describe-target-health --target-group-arn "$1" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text
}
blue_n=$(healthy_in "$BLUE_TG")
if [ "$blue_n" -lt 1 ]; then
  echo "Blue has no healthy instances left. It must stay warm for rollback."
  exit 1
fi
want=$blue_n
[ "$want" -lt 2 ] && want=2
green_ok() { [ "$(healthy_in "$GREEN_TG")" -ge "$want" ]; }
if ! wait_for "green to have $want healthy instances" 70 green_ok; then
  echo "Traffic is on green, but green has $(healthy_in "$GREEN_TG") healthy instance(s) while blue has $blue_n. Never move traffic to a smaller fleet than the one it replaces."
  exit 1
fi

BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
for i in $(seq 1 16); do
  page=$(docker exec "$BOX" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" | tr -d '\r' | tail -1)
  case "$page" in
    *"release 2"*) ;;
    *) echo "Request $i was answered by \"$page\" instead of release 2."; exit 1 ;;
  esac
done
echo "Cutover complete: release 2 answers everything from $(healthy_in "$GREEN_TG") healthy green instances; blue stays warm at weight 0 ($blue_n healthy)."
