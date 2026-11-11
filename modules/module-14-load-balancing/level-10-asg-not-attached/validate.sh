#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ASG=orbit-dispatch-asg
TG=$(aws_local elbv2 describe-target-groups --names orbit-dispatch --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
DNS=$(aws_local elbv2 describe-load-balancers --names orbit-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ] || [ -z "$DNS" ] || [ "$DNS" = "None" ]; then
  echo "orbit-alb or the target group orbit-dispatch is missing. Both were fine."
  exit 1
fi

attached=$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query "AutoScalingGroups[0].TargetGroupARNs[?@=='$TG'] | [0]" --output text)
if [ -z "$attached" ] || [ "$attached" = "None" ]; then
  echo "$ASG is not attached to the target group orbit-dispatch. Registering instance IDs by hand does not count: the next replacement instance would be left out."
  exit 1
fi

in_service() {
  [ "$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
    --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text)" -ge 2 ]
}
wait_for "two InService instances" 45 in_service || { echo "$ASG has fewer than two InService instances."; exit 1; }

two_healthy() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 2 ]
}
wait_for "both group instances healthy in the target group" 45 two_healthy || {
  echo "The group is attached, but orbit-dispatch does not show two healthy targets: $(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output text | tr '\t\n' ' ;')"
  exit 1
}

BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
page=$(docker exec "$BOX" bash -c \
  'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" | tr -d '\r')
if ! printf '%s' "$page" | head -1 | grep -q ' 200 ' || ! printf '%s' "$page" | grep -q 'Orbit dispatch node'; then
  echo "orbit-alb still fails: $(printf '%s' "$page" | head -1)"
  exit 1
fi

# Self-healing: kill one instance and watch the group replace it AND register the replacement.
victim=$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'] | [0].InstanceId" --output text)
before=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
  --query 'TargetHealthDescriptions[].Target.Id' --output text)
aws_local ec2 terminate-instances --instance-ids "$victim" >/dev/null
replaced() {
  local now id
  now=$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "TargetHealthDescriptions[?TargetHealth.State=='healthy'].Target.Id" --output text)
  [ "$(printf '%s\n' $now | grep -c .)" -ge 2 ] || return 1
  for id in $now; do
    [ "$id" = "$victim" ] && return 1
    case " $before " in *" $id "*) ;; *) return 0 ;; esac
  done
  return 1
}
if ! wait_for "a replacement instance to register and turn healthy" 70 replaced; then
  echo "After terminating $victim the group did not end up with a new healthy member in orbit-dispatch. The wiring between the group and the target group is still incomplete."
  exit 1
fi
echo "orbit-dispatch-asg is attached to orbit-dispatch: traffic flows, and a replacement instance registered itself."
