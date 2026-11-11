#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BOOT="$(mktemp)"
trap 'rm -f "$BOOT"' EXIT

spawn() {
  local tag="$1" az="$2" greeting="$3"
  cat > "$BOOT" <<SCRIPT
#!/bin/sh
cat > /site.sh <<'HANDLER'
#!/bin/sh
read -r q
while read -r hdr; do [ "\$hdr" = "\$(printf '\r')" ] && break; done
msg="$greeting"
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\${#msg}" "\$msg"
HANDLER
chmod +x /site.sh
nohup nc -lk -p 8080 -e /site.sh >/dev/null 2>&1 &
SCRIPT
  aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$az" --user-data "file://$BOOT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$tag}]" \
    --query 'Instances[0].InstanceId' --output text
}
group() {
  aws_local elbv2 create-target-group --name "$1" --protocol HTTP --port 8080 \
    --vpc-id vpc-default-us-east-1 --health-check-path / --health-check-interval-seconds 5 \
    --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text
}

MKT_I=$(spawn helix-marketing-1 a "HelixPay marketing site")
APP_I=$(spawn helix-portal-1 b "HelixPay customer portal")
MKT_TG=$(group helix-marketing)
APP_TG=$(group helix-portal)
aws_local elbv2 register-targets --target-group-arn "$MKT_TG" --targets "Id=$MKT_I"
aws_local elbv2 register-targets --target-group-arn "$APP_TG" --targets "Id=$APP_I"

# Floci keeps old load balancers in its HTTP data plane after a reset, and two of them claiming the
# same hostname on the same port confuse routing. A fresh random port per run avoids that.
PORT=$((10000 + (RANDOM * 32768 + RANDOM) % 40000))
LB=$(aws_local elbv2 create-load-balancer --name helix-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
L=$(aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port "$PORT" \
  --default-actions "Type=forward,TargetGroupArn=$MKT_TG" --query 'Listeners[0].ListenerArn' --output text)
aws_local elbv2 create-rule --listener-arn "$L" --priority 10 \
  --conditions '[{"Field":"host-header","Values":["portal.helixpay.example","app.helixpay.exmaple"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$APP_TG\"}]" >/dev/null

echo "helix-alb routes two hostnames to the customer portal fleet; one of them is not matching."
