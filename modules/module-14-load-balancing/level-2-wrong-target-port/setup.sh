#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BOOT="$(mktemp)"
trap 'rm -f "$BOOT"' EXIT
cat > "$BOOT" <<'SCRIPT'
#!/bin/sh
cat > /opt-tracker.sh <<'HANDLER'
#!/bin/sh
read -r first
want=$(echo "$first" | awk '{print $2}')
while read -r line; do [ "$line" = "$(printf '\r')" ] && break; done
if [ "$want" = "/status" ]; then
  code="200 OK"; payload='{"service":"tidewater-tracking","ready":true}'
elif [ "$want" = "/" ]; then
  code="200 OK"; payload="Tidewater tracking API ($(hostname))"
else
  code="404 Not Found"; payload="unknown route"
fi
printf 'HTTP/1.1 %s\r\nContent-Type: text/plain\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "$code" "${#payload}" "$payload"
HANDLER
chmod +x /opt-tracker.sh
nohup nc -lk -p 8080 -e /opt-tracker.sh >/dev/null 2>&1 &
SCRIPT

INSTANCE=$(aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
  --subnet-id subnet-default-us-east-1-b --user-data "file://$BOOT" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=tracking-api-1}]' \
  --query 'Instances[0].InstanceId' --output text)

TG=$(aws_local elbv2 create-target-group --name tracking-api --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /status --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name tidewater-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

# The deploy script registered the instance with an explicit port.
aws_local elbv2 register-targets --target-group-arn "$TG" --targets "Id=$INSTANCE,Port=80"

echo "tracking-api-1 is registered with tracking-api, and the target is unhealthy."
