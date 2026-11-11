#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ASG=lumen-api-asg
exists=$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --query 'length(AutoScalingGroups)' --output text)
if [ "$exists" != "1" ]; then
  echo "The Auto Scaling group $ASG was deleted. Fix it, do not remove it."
  exit 1
fi
read -r min max desired < <(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query 'AutoScalingGroups[0].[MinSize,MaxSize,DesiredCapacity]' --output text)

if [ "$min" -lt 2 ]; then
  echo "MinSize is $min. With a minimum below 2 the group (or a later scale-in) can leave the service without a spare instance."
  exit 1
fi
if [ "$desired" -lt 2 ]; then
  echo "DesiredCapacity is $desired; the service needs at least two instances running."
  exit 1
fi
if [ "$max" -lt 6 ]; then
  echo "MaxSize is $max. The group needs headroom to reach at least 6 instances during spikes."
  exit 1
fi
if [ "$max" -le "$desired" ]; then
  echo "MaxSize ($max) must be above DesiredCapacity ($desired), otherwise the group can never scale out."
  exit 1
fi

# Scheduled actions must not switch the service off again.
bad=$(aws_local autoscaling describe-scheduled-actions --auto-scaling-group-name "$ASG" \
  --query "ScheduledUpdateGroupActions[?MinSize==\`0\` || MaxSize==\`0\` || DesiredCapacity==\`0\`].ScheduledActionName" --output text)
if [ -n "$bad" ]; then
  echo "The scheduled action(s) [$bad] will scale the group back to zero. Remove or change them."
  exit 1
fi
low=$(aws_local autoscaling describe-scheduled-actions --auto-scaling-group-name "$ASG" \
  --query "ScheduledUpdateGroupActions[?MinSize!=null && MinSize<\`2\`].ScheduledActionName" --output text)
if [ -n "$low" ]; then
  echo "The scheduled action(s) [$low] would drop MinSize below 2."
  exit 1
fi

serving() {
  [ "$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
    --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text)" -ge 2 ]
}
if ! wait_for "two instances in service" 60 serving; then
  echo "Capacity is configured, but fewer than two instances are InService yet: $(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --query 'AutoScalingGroups[0].Instances[].[InstanceId,LifecycleState]' --output text | tr '\t\n' ' ;')"
  exit 1
fi

TG=$(aws_local elbv2 describe-target-groups --names lumen-api --query 'TargetGroups[0].TargetGroupArn' --output text)
two_healthy() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 2 ]
}
wait_for "two healthy targets" 45 two_healthy || { echo "Instances are running but fewer than two are healthy in lumen-api yet."; exit 1; }

DNS=$(aws_local elbv2 describe-load-balancers --names lumen-alb --query 'LoadBalancers[0].DNSName' --output text)
BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
page=$(docker exec "$BOX" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" | tr -d '\r')
if ! printf '%s' "$page" | head -1 | grep -q ' 200 ' || ! printf '%s' "$page" | grep -q 'Lumenbeam thumbnails'; then
  echo "lumen-alb still does not serve the API: $(printf '%s' "$page" | head -1)"
  exit 1
fi
echo "lumen-alb is serving from $min+ healthy instances (min $min / desired $desired / max $max) and no scheduled action zeroes the group."
