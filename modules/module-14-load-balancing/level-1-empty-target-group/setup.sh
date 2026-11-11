#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

APP="$(mktemp)"
trap 'rm -f "$APP"' EXIT
cat > "$APP" <<'SCRIPT'
#!/bin/sh
cat > /srv-handler.sh <<'HANDLER'
#!/bin/sh
read -r request_line
path=$(echo "$request_line" | cut -d' ' -f2)
while read -r header; do [ "$header" = "$(printf '\r')" ] && break; done
case "$path" in
  /health) status="200 OK"; body="ok" ;;
  /)       status="200 OK"; body="Pageturn Books storefront - served by $(hostname)" ;;
  *)       status="404 Not Found"; body="not found" ;;
esac
printf 'HTTP/1.1 %s\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "$status" "${#body}" "$body"
HANDLER
chmod +x /srv-handler.sh
nohup nc -lk -p 8080 -e /srv-handler.sh >/dev/null 2>&1 &
SCRIPT

aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
  --subnet-id subnet-default-us-east-1-a --user-data "file://$APP" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pageturn-web-1}]' >/dev/null

TG=$(aws_local elbv2 create-target-group --name pageturn-web --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /health --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name pageturn-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

echo "pageturn-alb is active, pageturn-web-1 is running, and visitors get HTTP 503."
