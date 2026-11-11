#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# 1. Capacity first: bring green up to blue's size.
aws_local autoscaling update-auto-scaling-group --auto-scaling-group-name saffron-green-asg \
  --min-size 2 --desired-capacity 2

# 2. Edit the player's copy of the action: blue 0, green 100.
python3 - <<'PY'
import json
actions = json.load(open("listener-actions.json"))
groups = actions[0]["ForwardConfig"]["TargetGroups"]
for group in groups:
    group["Weight"] = 100 if "saffron-green" in group["TargetGroupArn"] else 0
json.dump(actions, open("listener-actions.json", "w"), indent=2)
PY

# 3. Wait until green is healthy at full size, then shift traffic.
GREEN_TG=$(aws_local elbv2 describe-target-groups --names saffron-green --query 'TargetGroups[0].TargetGroupArn' --output text)
green_ready() {
  [ "$(aws_local elbv2 describe-target-health --target-group-arn "$GREEN_TG" \
    --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" --output text)" -ge 2 ]
}
wait_for "green fleet healthy at size 2" 90 green_ready

LB=$(aws_local elbv2 describe-load-balancers --names saffron-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER=$(aws_local elbv2 describe-listeners --load-balancer-arn "$LB" --query 'Listeners[0].ListenerArn' --output text)
aws_local elbv2 modify-listener --listener-arn "$LISTENER" --default-actions file://listener-actions.json
