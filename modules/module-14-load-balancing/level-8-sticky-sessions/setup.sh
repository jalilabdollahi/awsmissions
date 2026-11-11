#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Each shopper's cart lives in the memory of the server that first saw them.
APPSRC="$(mktemp)"
trap 'rm -f "$APPSRC"' EXIT
printf '%s\n' \
  '#!/bin/sh' \
  'cat > /kestrel-cart.sh <<"EOF"' \
  '#!/bin/sh' \
  'IFS= read -r first' \
  'set -- $first' \
  'while IFS= read -r h; do [ "$h" = "$(printf "\r")" ] && break; done' \
  'msg="Kestrel cart served by $(hostname)"' \
  '[ "$2" = "/up" ] && msg=up' \
  'printf "HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s" "${#msg}" "$msg"' \
  'EOF' \
  'chmod +x /kestrel-cart.sh' \
  'nohup nc -lk -p 8080 -e /kestrel-cart.sh >/dev/null 2>&1 &' > "$APPSRC"

group_arn=$(aws_local elbv2 create-target-group --name kestrel-web --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /up --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

first=$(aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
  --subnet-id subnet-default-us-east-1-a --user-data "file://$APPSRC" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=kestrel-web-1}]' \
  --query 'Instances[0].InstanceId' --output text)
second=$(aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
  --subnet-id subnet-default-us-east-1-c --user-data "file://$APPSRC" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=kestrel-web-2}]' \
  --query 'Instances[0].InstanceId' --output text)
aws_local elbv2 register-targets --target-group-arn "$group_arn" --targets "Id=$first" "Id=$second"

alb_arn=$(aws_local elbv2 create-load-balancer --name kestrel-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-c \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$alb_arn" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$group_arn" >/dev/null

echo "kestrel-web has two servers and no session affinity."
