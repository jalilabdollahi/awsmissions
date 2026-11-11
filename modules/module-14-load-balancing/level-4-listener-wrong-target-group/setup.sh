#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BOOT="$(mktemp)"
trap 'rm -f "$BOOT"' EXIT

# Same tiny web app on both fleets; only the banner differs.
launch_portal() {
  local name="$1" banner="$2" az="$3"
  cat > "$BOOT" <<SCRIPT
#!/bin/sh
cat > /portal.sh <<'HANDLER'
#!/bin/sh
read -r l
p=\$(echo "\$l" | cut -d' ' -f2)
while read -r h; do [ "\$h" = "\$(printf '\r')" ] && break; done
case "\$p" in
  /ping) st="200 OK"; b="pong" ;;
  /)     st="200 OK"; b="$banner" ;;
  *)     st="404 Not Found"; b="missing" ;;
esac
printf 'HTTP/1.1 %s\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\$st" "\${#b}" "\$b"
HANDLER
chmod +x /portal.sh
nohup nc -lk -p 8080 -e /portal.sh >/dev/null 2>&1 &
SCRIPT
  aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro \
    --subnet-id "subnet-default-us-east-1-$az" --user-data "file://$BOOT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' --output text
}

mk_group() {
  aws_local elbv2 create-target-group --name "$1" --protocol HTTP --port 8080 \
    --vpc-id vpc-default-us-east-1 --health-check-path /ping --health-check-interval-seconds 5 \
    --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' --output text
}

PROD_I=$(launch_portal portal-prod-1 "Maplewood Online Banking (production)" a)
STAGE_I=$(launch_portal portal-staging-1 "STAGING BUILD 2.9-rc1 - not for members" b)
PROD_TG=$(mk_group portal-prod)
STAGE_TG=$(mk_group portal-staging)
aws_local elbv2 register-targets --target-group-arn "$PROD_TG" --targets "Id=$PROD_I"
aws_local elbv2 register-targets --target-group-arn "$STAGE_TG" --targets "Id=$STAGE_I"

LB=$(aws_local elbv2 create-load-balancer --name maplewood-alb \
  --subnets subnet-default-us-east-1-a subnet-default-us-east-1-b \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
# The rehearsal pointed the listener at staging and nobody pointed it back.
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$STAGE_TG" >/dev/null

echo "Both fleets are healthy; maplewood-alb sends members to the wrong one."
