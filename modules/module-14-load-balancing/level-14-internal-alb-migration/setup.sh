#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

UD="$(mktemp)"
trap 'rm -f "$UD"' EXIT

# $1 tag, $2 az letter, $3 greeting
fleet_member() {
  cat > "$UD" <<SCRIPT
#!/bin/sh
cat > /gw-app.sh <<'HANDLER'
#!/bin/sh
read -r req
while read -r hdr; do [ "\$hdr" = "\$(printf '\r')" ] && break; done
case "\$(echo "\$req" | awk '{print \$2}')" in
  /up) text=up ;;
  *)   text="$3" ;;
esac
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\${#text}" "\$text"
HANDLER
chmod +x /gw-app.sh
nohup nc -lk -p 8080 -e /gw-app.sh >/dev/null 2>&1 &
SCRIPT
  aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$2" --user-data "file://$UD" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" \
    --query 'Instances[0].InstanceId' --output text
}
fleet_group() {
  aws_local elbv2 create-target-group --name "$1" --protocol HTTP --port 8080 \
    --vpc-id vpc-default-us-east-1 --health-check-path /up --health-check-interval-seconds 5 \
    --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text
}

WEB_I=$(fleet_member nimbus-web-1 a "Nimbus Notes web app")
API_I=$(fleet_member nimbus-api-1 b "Nimbus Notes REST API")
WEB_TG=$(fleet_group nimbus-web)
API_TG=$(fleet_group nimbus-api)
aws_local elbv2 register-targets --target-group-arn "$WEB_TG" --targets "Id=$WEB_I"
aws_local elbv2 register-targets --target-group-arn "$API_TG" --targets "Id=$API_I"

# Floci keeps deleted or reset load balancers in its HTTP data plane, so identical host rules on the
# same port would collide between runs. Each run gets its own listener port; the port is recorded
# as a tag on the web target group, where the check later finds it.
PORT=$((10000 + (RANDOM * 32768 + RANDOM) % 40000))
aws_local elbv2 add-tags --resource-arns "$WEB_TG" --tags "Key=listener-port,Value=$PORT"
LB=$(aws_local elbv2 create-load-balancer --name nimbus-gateway --scheme internal \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
L=$(aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port "$PORT" \
  --default-actions "Type=forward,TargetGroupArn=$WEB_TG" --query 'Listeners[0].ListenerArn' --output text)
aws_local elbv2 create-rule --listener-arn "$L" --priority 10 \
  --conditions '[{"Field":"path-pattern","Values":["/status"]}]' \
  --actions '[{"Type":"fixed-response","FixedResponseConfig":{"StatusCode":"200","ContentType":"text/plain","MessageBody":"nimbus gateway: all systems go"}}]' >/dev/null
aws_local elbv2 create-rule --listener-arn "$L" --priority 20 \
  --conditions '[{"Field":"host-header","Values":["api.nimbusnotes.example"]}]' \
  --actions "[{\"Type\":\"forward\",\"TargetGroupArn\":\"$API_TG\"}]" >/dev/null

echo "nimbus-gateway is internal, with two rules and a default forward on port $PORT."
