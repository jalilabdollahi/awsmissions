#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

UD="$(mktemp)"
trap 'rm -f "$UD"' EXIT
cat > "$UD" <<'SCRIPT'
#!/bin/sh
cat > /dispatch.sh <<'HANDLER'
#!/bin/sh
read -r request_line
url=$(echo "$request_line" | awk '{print $2}')
while read -r hdr; do [ "$hdr" = "$(printf '\r')" ] && break; done
case "$url" in
  /status) reply='{"ok":true}' ;;
  *)       reply="Orbit dispatch node $(hostname)" ;;
esac
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "${#reply}" "$reply"
HANDLER
chmod +x /dispatch.sh
nohup nc -lk -p 8080 -e /dispatch.sh >/dev/null 2>&1 &
SCRIPT
B64=$(base64 < "$UD" | tr -d '\n')
aws_local ec2 create-launch-template --launch-template-name orbit-dispatch-lt \
  --launch-template-data "{\"ImageId\":\"ami-alpine\",\"InstanceType\":\"t3.micro\",\"UserData\":\"$B64\"}" >/dev/null

TG=$(aws_local elbv2 create-target-group --name orbit-dispatch --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /status --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name orbit-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

# The group was created without --target-group-arns.
aws_local autoscaling create-auto-scaling-group --auto-scaling-group-name orbit-dispatch-asg \
  --launch-template "LaunchTemplateName=orbit-dispatch-lt,Version=\$Latest" \
  --min-size 2 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "subnet-default-us-east-1-a,subnet-default-us-east-1-b" \
  --health-check-type EC2 --health-check-grace-period 60

echo "orbit-dispatch-asg is launching two instances; orbit-dispatch has no targets."
