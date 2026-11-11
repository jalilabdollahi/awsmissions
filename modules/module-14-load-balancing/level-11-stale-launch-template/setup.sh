#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# One bootstrap script per release. Only the port and the banner differ on purpose.
write_boot() {
  local file="$1" port="$2" banner="$3"
  cat > "$file" <<SCRIPT
#!/bin/sh
cat > /route.sh <<'HANDLER'
#!/bin/sh
read -r l
p=\$(echo "\$l" | awk '{print \$2}')
while read -r h; do [ "\$h" = "\$(printf '\r')" ] && break; done
if [ "\$p" = "/ready" ]; then t="ready"; else t="$banner"; fi
printf 'HTTP/1.1 200 OK\r\nContent-Length: %s\r\nConnection: close\r\n\r\n%s' "\${#t}" "\$t"
HANDLER
chmod +x /route.sh
nohup nc -lk -p $port -e /route.sh >/dev/null 2>&1 &
SCRIPT
}
write_boot "$WORK/v1.sh" 9090 "Parcelway routing release 2.3"
write_boot "$WORK/v2.sh" 8080 "Parcelway routing release 2.4"
V1=$(base64 < "$WORK/v1.sh" | tr -d '\n')
V2=$(base64 < "$WORK/v2.sh" | tr -d '\n')

aws_local ec2 create-launch-template --launch-template-name parcelway-lt \
  --version-description "release 2.3" \
  --launch-template-data "{\"ImageId\":\"ami-alpine\",\"InstanceType\":\"t3.micro\",\"UserData\":\"$V1\"}" >/dev/null
aws_local ec2 create-launch-template-version --launch-template-name parcelway-lt \
  --source-version 1 --version-description "release 2.4 - fixed port" \
  --launch-template-data "{\"UserData\":\"$V2\"}" >/dev/null

TG=$(aws_local elbv2 create-target-group --name parcelway-routing --protocol HTTP --port 8080 \
  --vpc-id vpc-default-us-east-1 --health-check-path /ready --health-check-interval-seconds 5 \
  --healthy-threshold-count 2 --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)
LB=$(aws_local elbv2 create-load-balancer --name parcelway-alb \
  --subnets subnet-default-us-east-1-b subnet-default-us-east-1-c \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws_local elbv2 create-listener --load-balancer-arn "$LB" --protocol HTTP --port 80 \
  --default-actions "Type=forward,TargetGroupArn=$TG" >/dev/null

# The group is pinned to version 1.
aws_local autoscaling create-auto-scaling-group --auto-scaling-group-name parcelway-asg \
  --launch-template "LaunchTemplateName=parcelway-lt,Version=1" \
  --min-size 2 --max-size 4 --desired-capacity 2 \
  --vpc-zone-identifier "subnet-default-us-east-1-b,subnet-default-us-east-1-c" \
  --target-group-arns "$TG" --health-check-type EC2 --health-check-grace-period 30

echo "parcelway-asg launches from parcelway-lt version 1; version 2 is waiting unused."
