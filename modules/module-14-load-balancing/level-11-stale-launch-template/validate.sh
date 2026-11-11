#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ASG=parcelway-asg
TG=$(aws_local elbv2 describe-target-groups --names parcelway-routing --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
DNS=$(aws_local elbv2 describe-load-balancers --names parcelway-alb --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || true)
if [ -z "$TG" ] || [ "$TG" = "None" ] || [ -z "$DNS" ] || [ "$DNS" = "None" ]; then
  echo "parcelway-alb or its target group is missing."
  exit 1
fi

# The newest launch template version is the corrected one.
newest=$(aws_local ec2 describe-launch-template-versions --launch-template-name parcelway-lt \
  --query 'max(LaunchTemplateVersions[].VersionNumber)' --output text)
cfg=$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query 'AutoScalingGroups[0].LaunchTemplate.[LaunchTemplateName,Version]' --output text)
cfg_name=$(printf '%s' "$cfg" | awk '{print $1}')
cfg_ver=$(printf '%s' "$cfg" | awk '{print $2}')
if [ "$cfg_name" != "parcelway-lt" ]; then
  echo "The group must keep using the launch template parcelway-lt (it uses '$cfg_name')."
  exit 1
fi
case "$cfg_ver" in
  1) echo "The group is still pinned to launch template version 1, so every new instance gets the old startup script."; exit 1 ;;
  '$Latest'|"$newest") ;;
  '$Default') 
    default=$(aws_local ec2 describe-launch-templates --launch-template-names parcelway-lt --query 'LaunchTemplates[0].DefaultVersionNumber' --output text)
    if [ "$default" != "$newest" ]; then echo "The group follows \$Default, which is still version $default, not the corrected version $newest."; exit 1; fi ;;
  *) echo "The group uses launch template version '$cfg_ver', not the corrected one."; exit 1 ;;
esac

# Every instance must come from the corrected version.
old=$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
  --query "AutoScalingGroups[0].Instances[?LaunchTemplate.Version=='1'].InstanceId" --output text)
if [ -n "$old" ]; then
  # Give an instance refresh a fair chance to finish before judging.
  none_old() {
    [ -z "$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
      --query "AutoScalingGroups[0].Instances[?LaunchTemplate.Version=='1'].InstanceId" --output text)" ]
  }
  wait_for "old-version instances to be replaced" 50 none_old || {
    echo "These instances still run launch template version 1: $old. The group config is not enough; the running instances have to be replaced."
    exit 1
  }
fi

settled_healthy() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 2 ] &&
  [ "$(aws_local autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" \
    --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text)" -ge 2 ]
}
wait_for "two healthy release 2.4 instances" 60 settled_healthy || {
  echo "Fewer than two healthy targets right now: $(aws_local elbv2 describe-target-health --target-group-arn "$TG" --query 'TargetHealthDescriptions[].[Target.Id,Target.Port,TargetHealth.State]' --output text | tr '\t\n' ' ;')"
  exit 1
}

BOX="awsmissions-floci"
[ "${AWSMISSIONS_PORT:-4566}" = "4566" ] || BOX="awsmissions-floci-${AWSMISSIONS_PORT}"
for i in 1 2 3 4 5 6; do
  page=$(docker exec "$BOX" bash -c \
    'exec 3<>/dev/tcp/127.0.0.1/80; printf "GET / HTTP/1.0\r\nHost: %s\r\n\r\n" "$1" >&3; cat <&3' _ "$DNS" | tr -d '\r' | tail -1)
  case "$page" in
    *"release 2.4"*) ;;
    *) echo "Request $i through parcelway-alb answered: \"$page\" instead of release 2.4."; exit 1 ;;
  esac
done
echo "parcelway-alb serves release 2.4 from healthy instances, and the group uses the corrected template (version $cfg_ver)."
