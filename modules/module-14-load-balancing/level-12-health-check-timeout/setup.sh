#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

UD="$(mktemp)"
trap 'rm -f "$UD"' EXIT
cat > "$UD" <<'SCRIPT'
#!/bin/sh
cat > /dash-api.sh <<'HANDLER'
#!/bin/sh
read -r req
route=$(echo "$req" | awk '{print $2}')
while read -r hdr; do [ "$hdr" = "$(printf '\r')" ] && break; done
case "$route" in
  /health) sleep 7; msg='{"db":"ok"}' ;;
  /livez)  msg='alive' ;;
  *)       msg="Fathomly dashboard API on $(hostname)" ;;
esac
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "${#msg}" "$msg"
HANDLER
chmod +x /dash-api.sh
nohup nc -lk -p 8080 -e /dash-api.sh >/dev/null 2>&1 &
SCRIPT

# 5s timeout, 10s interval: the deep check needs about 7s.
TG=$(aws_local elbv2 create-target-group --name fathomly-api --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /health \
  --health-check-interval-seconds 10 --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
for n in 1 2; do
  az="a"; [ "$n" = "2" ] && az="b"
  id=$(aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$az" --user-data "file://$UD" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=fathomly-api-$n}]" \
    --query 'Instances[0].InstanceId' --output text)
  aws_local elbv2 register-targets --target-group-arn "$TG" --targets "Id=$id"
done
LB=$(aws_local elbv2 create-load-balancer --name fathomly-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

echo "fathomly-api targets time out their health checks."
