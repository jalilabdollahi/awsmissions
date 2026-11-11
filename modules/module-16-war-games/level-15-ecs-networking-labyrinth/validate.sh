#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

bad=0
echo "mt-gateway network audit (INC-5561)"

VPC="$(aws_local ec2 describe-vpcs --filters Name=cidr,Values=10.30.0.0/16 --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)"
if [ -z "$VPC" ] || [ "$VPC" = "None" ]; then echo "mt-vpc is gone."; exit 1; fi
PRIV="$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=cidr-block,Values=10.30.2.0/24 --query 'Subnets[0].SubnetId' --output text)"
PUB="$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=cidr-block,Values=10.30.1.0/24 --query 'Subnets[0].SubnetId' --output text)"
GWSG="$(aws_local ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC" Name=group-name,Values=mt-gateway-sg --query 'SecurityGroups[0].GroupId' --output text)"
ALBSG="$(aws_local ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC" Name=group-name,Values=mt-alb-sg --query 'SecurityGroups[0].GroupId' --output text)"
NAT="$(aws_local ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC" --query 'NatGateways[?State!=`deleted`].NatGatewayId | [0]' --output text 2>/dev/null || true)"
for x in "$PRIV" "$PUB" "$GWSG" "$ALBSG"; do
  if [ -z "$x" ] || [ "$x" = "None" ]; then echo "Part of the mt-vpc network (a subnet or security group) is missing. Repair, don't rebuild."; exit 1; fi
done
if [ -z "$NAT" ] || [ "$NAT" = "None" ]; then echo "The NAT gateway mt-nat is gone."; exit 1; fi

# 1: ECS placement.
svc="$(aws_local ecs describe-services --cluster mt-prod --services mt-gateway --query 'services[0]' --output json 2>/dev/null || echo null)"
if [ "$svc" = "null" ]; then echo "The mt-gateway service is gone."; exit 1; fi
nsub="$(printf '%s' "$svc" | jq -r '.networkConfiguration.awsvpcConfiguration.subnets | join(",")')"
pubip="$(printf '%s' "$svc" | jq -r '.networkConfiguration.awsvpcConfiguration.assignPublicIp')"
sgs="$(printf '%s' "$svc" | jq -r '.networkConfiguration.awsvpcConfiguration.securityGroups | join(",")')"
if [ "$nsub" != "$PRIV" ]; then
  echo "[FAULT] placement  the service is configured for subnet(s) $nsub, not only the private subnet"
  bad=$((bad + 1))
elif [ "$pubip" != "DISABLED" ]; then
  echo "[FAULT] placement  the service still assigns public IPs to its tasks"
  bad=$((bad + 1))
elif [ "$sgs" != "$GWSG" ]; then
  echo "[FAULT] placement  the service does not use mt-gateway-sg"
  bad=$((bad + 1))
else
  on_private() {
    local n=0
    for t in $(aws_local ecs list-tasks --cluster mt-prod --service-name mt-gateway --desired-status RUNNING --query 'taskArns' --output text); do
      s="$(aws_local ecs describe-tasks --cluster mt-prod --tasks "$t" --query 'tasks[0].attachments[0].details[?name==`subnetId`].value | [0]' --output text)"
      [ "$s" = "$PRIV" ] && n=$((n + 1))
      [ "$s" != "$PRIV" ] && return 1
    done
    [ "$n" -ge 1 ]
  }
  if wait_for "tasks to settle in the private subnet" 60 on_private; then
    echo "[ok]    placement  running tasks live only in the private subnet, without public IPs"
  else
    echo "[FAULT] placement  the service is configured correctly but its running tasks are not (all) in the private subnet yet"
    bad=$((bad + 1))
  fi
fi

# 2: default route of the private subnet.
rt="$(aws_local ec2 describe-route-tables --filters Name=association.subnet-id,Values="$PRIV" --query 'RouteTables[0]' --output json)"
nat_route="$(printf '%s' "$rt" | jq -r '[.Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0")] | first | (.NatGatewayId // "")')"
igw_route="$(printf '%s' "$rt" | jq -r '[.Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0" and ((.GatewayId // "") | startswith("igw-")))] | length')"
if [ "$igw_route" != "0" ]; then
  echo "BLOCKER: the private subnet now routes 0.0.0.0/0 straight to an internet gateway. That makes it a public subnet."
  exit 1
fi
if [ "$nat_route" = "$NAT" ]; then
  echo "[ok]    route      the private subnet's default route goes through mt-nat"
else
  echo "[FAULT] route      the private subnet has no default route through the NAT gateway"
  bad=$((bad + 1))
fi

# 3 + 4: security group rules.
sgj="$(aws_local ec2 describe-security-groups --group-ids "$GWSG" --query 'SecurityGroups[0]' --output json)"
eg443="$(printf '%s' "$sgj" | jq '[.IpPermissionsEgress[] | select((.IpProtocol == "-1") or (.IpProtocol == "tcp" and (.FromPort // 0) <= 443 and (.ToPort // 65535) >= 443)) | select(any(.IpRanges[]?; .CidrIp == "0.0.0.0/0"))] | length')"
if [ "$eg443" -ge 1 ]; then
  echo "[ok]    egress     the tasks may make outbound HTTPS calls"
else
  echo "[FAULT] egress     the security group does not allow outbound HTTPS"
  bad=$((bad + 1))
fi
world="$(printf '%s' "$sgj" | jq '[.IpPermissions[] | select(any(.IpRanges[]?; .CidrIp == "0.0.0.0/0"))] | length')"
if [ "$world" != "0" ]; then
  echo "BLOCKER: mt-gateway-sg accepts inbound traffic from 0.0.0.0/0. Only the load balancer's group may reach port 8080."
  exit 1
fi
from_alb="$(printf '%s' "$sgj" | jq --arg alb "$ALBSG" '[.IpPermissions[] | select(.IpProtocol == "tcp" and (.FromPort // 0) <= 8080 and (.ToPort // 0) >= 8080) | select(any(.UserIdGroupPairs[]?; .GroupId == $alb))] | length')"
if [ "$from_alb" -ge 1 ]; then
  echo "[ok]    ingress    the load balancer can reach port 8080"
else
  echo "[FAULT] ingress    nothing allows the load balancer to reach the tasks on port 8080"
  bad=$((bad + 1))
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) still broken."
  exit 1
fi
echo "mt-gateway runs privately, routes out through the NAT, accepts the load balancer only, and can make HTTPS calls."
