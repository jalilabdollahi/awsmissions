#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BOOT="$(mktemp)"
trap 'rm -f "$BOOT"' EXIT

# $1 = Name tag, $2 = AZ letter, $3 = text every route answers with
start_backend() {
  cat > "$BOOT" <<SCRIPT
#!/bin/sh
cat > /backend.sh <<'HANDLER'
#!/bin/sh
read -r request
route=\$(echo "\$request" | awk '{print \$2}')
while read -r hdr; do [ "\$hdr" = "\$(printf '\r')" ] && break; done
if [ "\$route" = "/ping" ]; then text="pong"; else text="$3 route=\$route"; fi
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\${#text}" "\$text"
HANDLER
chmod +x /backend.sh
nohup nc -lk -p 8080 -e /backend.sh >/dev/null 2>&1 &
SCRIPT
  aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$2" --user-data "file://$BOOT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" \
    --query 'Instances[0].InstanceId' --output text
}
new_group() {
  aws_local elbv2 create-target-group --name "$1" --protocol HTTP --port 8080 \
    --vpc-id vpc-default-us-east-1 --health-check-path /ping --health-check-interval-seconds 5 \
    --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text
}

WEB_I=$(start_backend corallo-shop-1 a "Corallo shop front end")
API_I=$(start_backend corallo-api-1 b "Corallo API")
WEB_TG=$(new_group corallo-shop)
API_TG=$(new_group corallo-api)
aws_local elbv2 register-targets --target-group-arn "$WEB_TG" --targets "Id=$WEB_I"
aws_local elbv2 register-targets --target-group-arn "$API_TG" --targets "Id=$API_I"

LB=$(aws_local elbv2 create-load-balancer --name corallo-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
LISTENER=$(aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$WEB_TG" --query 'Listeners[0].ListenerArn' --output text)

aws_local elbv2 create-rule --listener-arn "$LISTENER" --priority 10 \
  --conditions '[{"Field":"path-pattern","Values":["/api/*"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$API_TG\"}]" >/dev/null
aws_local elbv2 create-rule --listener-arn "$LISTENER" --priority 20 \
  --conditions '[{"Field":"path-pattern","Values":["/api/admin/*"]}]' \
  --actions '[{"Type":"fixed-response","FixedResponseConfig":{"StatusCode":"403","ContentType":"text/plain","MessageBody":"admin area is not public"}}]' >/dev/null

echo "corallo-alb has three routes: /api/admin/* (block), /api/* (API fleet), default (shop)."
