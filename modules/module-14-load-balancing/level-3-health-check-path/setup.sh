#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BOOT="$(mktemp)"
trap 'rm -f "$BOOT"' EXIT
cat > "$BOOT" <<'SCRIPT'
#!/bin/sh
cat > /api-router.sh <<'HANDLER'
#!/bin/sh
read -r first_line
route=$(echo "$first_line" | cut -d' ' -f2)
while read -r hdr; do [ "$hdr" = "$(printf '\r')" ] && break; done
case "$route" in
  /healthz) code="200 OK";        text='{"alive":true}' ;;
  /orders)  code="200 OK";        text='{"orders":[]}' ;;
  *)        code="404 Not Found"; text='{"error":"no such route"}' ;;
esac
printf 'HTTP/1.1 %s\r\nContent-Type: application/json\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "$code" "${#text}" "$text"
HANDLER
chmod +x /api-router.sh
nohup nc -lk -p 8080 -e /api-router.sh >/dev/null 2>&1 &
SCRIPT

IDS=""
for n in 1 2; do
  az="a"; [ "$n" = "2" ] && az="b"
  id=$(aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$az" --user-data "file://$BOOT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=brewline-api-$n}]" \
    --query 'Instances[0].InstanceId' --output text)
  IDS="$IDS Id=$id"
done

# Terraform's defaults: path "/" and only HTTP 200 counts as success.
TG=$(aws_local elbv2 create-target-group --name brewline-orders --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name brewline-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null
# shellcheck disable=SC2086
aws_local elbv2 register-targets --target-group-arn "$TG" --targets $IDS

echo "brewline-orders has two targets and both are failing their health check."
