#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

release_script() {
  cat > "$TMP/$1.sh" <<SCRIPT
#!/bin/sh
cat > /checkout.sh <<'HANDLER'
#!/bin/sh
read -r rq
pth=\$(echo "\$rq" | awk '{print \$2}')
while read -r hd; do [ "\$hd" = "\$(printf '\r')" ] && break; done
if [ "\$pth" = "/healthz" ]; then out=ok; else out="Saffron checkout $2"; fi
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\${#out}" "\$out"
HANDLER
chmod +x /checkout.sh
nohup nc -lk -p 8080 -e /checkout.sh >/dev/null 2>&1 &
SCRIPT
}
release_script blue "release 1"
release_script green "release 2"
for color in blue green; do
  b64=$(base64 < "$TMP/$color.sh" | tr -d '\n')
  aws_local ec2 create-launch-template --launch-template-name "saffron-$color-lt" \
    --launch-template-data "{\"ImageId\":\"ami-alpine\",\"InstanceType\":\"t3.micro\",\"UserData\":\"$b64\"}" >/dev/null
  aws_local elbv2 create-target-group --name "saffron-$color" --protocol HTTP --port 8080 \
    --vpc-id vpc-default-us-east-1 --health-check-path /healthz --health-check-interval-seconds 5 \
    --healthy-threshold-count 2 --unhealthy-threshold-count 2 >/dev/null
done
BLUE_TG=$(aws_local elbv2 describe-target-groups --names saffron-blue --query 'TargetGroups[0].TargetGroupArn' --output text)
GREEN_TG=$(aws_local elbv2 describe-target-groups --names saffron-green --query 'TargetGroups[0].TargetGroupArn' --output text)

aws_local autoscaling create-auto-scaling-group --auto-scaling-group-name saffron-blue-asg \
  --launch-template "LaunchTemplateName=saffron-blue-lt,Version=\$Latest" \
  --min-size 2 --max-size 6 --desired-capacity 2 \
  --vpc-zone-identifier "subnet-default-us-east-1-a,subnet-default-us-east-1-b" \
  --target-group-arns "$BLUE_TG" --health-check-type ELB --health-check-grace-period 30
aws_local autoscaling create-auto-scaling-group --auto-scaling-group-name saffron-green-asg \
  --launch-template "LaunchTemplateName=saffron-green-lt,Version=\$Latest" \
  --min-size 1 --max-size 6 --desired-capacity 1 \
  --vpc-zone-identifier "subnet-default-us-east-1-a,subnet-default-us-east-1-b" \
  --target-group-arns "$GREEN_TG" --health-check-type ELB --health-check-grace-period 30

LB=$(aws_local elbv2 create-load-balancer --name saffron-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
ACTIONS="[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":[{\"TargetGroupArn\":\"$BLUE_TG\",\"Weight\":100},{\"TargetGroupArn\":\"$GREEN_TG\",\"Weight\":0}]}}]"
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "$ACTIONS" >/dev/null

# The player's copy of the current action, with this run's real ARNs, ready to edit.
if [ -n "${WORKDIR:-}" ] && [ -d "$WORKDIR" ]; then
  python3 - "$ACTIONS" > "$WORKDIR/listener-actions.json" <<'PY'
import json, sys
print(json.dumps(json.loads(sys.argv[1]), indent=2))
PY
fi

echo "saffron-alb sends 100% to blue (2 instances); green has 1 instance and weight 0."
