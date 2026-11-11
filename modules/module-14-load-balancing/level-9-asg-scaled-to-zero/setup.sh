#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

UD="$(mktemp)"
trap 'rm -f "$UD"' EXIT
cat > "$UD" <<'SCRIPT'
#!/bin/sh
cat > /thumbs.sh <<'HANDLER'
#!/bin/sh
read -r rl
rp=$(echo "$rl" | awk '{print $2}')
while read -r h; do [ "$h" = "$(printf '\r')" ] && break; done
case "$rp" in
  /healthz) out="ok" ;;
  *)        out="Lumenbeam thumbnails ready on $(hostname)" ;;
esac
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "${#out}" "$out"
HANDLER
chmod +x /thumbs.sh
nohup nc -lk -p 8080 -e /thumbs.sh >/dev/null 2>&1 &
SCRIPT
B64=$(base64 < "$UD" | tr -d '\n')
aws_local ec2 create-launch-template --launch-template-name lumen-api-lt \
  --launch-template-data "{\"ImageId\":\"ami-alpine\",\"InstanceType\":\"t3.micro\",\"UserData\":\"$B64\"}" >/dev/null

TG=$(aws_local elbv2 create-target-group --name lumen-api --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /healthz --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name lumen-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

# "Night mode": the group exists but was scaled to nothing.
aws_local autoscaling create-auto-scaling-group --auto-scaling-group-name lumen-api-asg \
  --launch-template "LaunchTemplateName=lumen-api-lt,Version=\$Latest" \
  --min-size 0 --max-size 2 --desired-capacity 0 \
  --vpc-zone-identifier "subnet-default-us-east-1-a,subnet-default-us-east-1-b" \
  --target-group-arns "$TG" --health-check-type ELB --health-check-grace-period 60
aws_local autoscaling put-scheduled-update-group-action --auto-scaling-group-name lumen-api-asg \
  --scheduled-action-name nightly-shutdown --recurrence "0 22 * * *" \
  --min-size 0 --max-size 0 --desired-capacity 0

echo "lumen-api-asg has no instances, and a scheduled action keeps it that way."
