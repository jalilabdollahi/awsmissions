#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC="$(aws_local ec2 describe-vpcs --filters Name=cidr,Values=10.30.0.0/16 --query 'Vpcs[0].VpcId' --output text)"
PRIV="$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=cidr-block,Values=10.30.2.0/24 --query 'Subnets[0].SubnetId' --output text)"
GWSG="$(aws_local ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC" Name=group-name,Values=mt-gateway-sg --query 'SecurityGroups[0].GroupId' --output text)"
ALBSG="$(aws_local ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC" Name=group-name,Values=mt-alb-sg --query 'SecurityGroups[0].GroupId' --output text)"
NAT="$(aws_local ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC" --query 'NatGateways[0].NatGatewayId' --output text)"
RT="$(aws_local ec2 describe-route-tables --filters Name=association.subnet-id,Values="$PRIV" --query 'RouteTables[0].RouteTableId' --output text)"

# 1. Run the service in the private subnet, no public IP.
aws_local ecs update-service --cluster mt-prod --service mt-gateway --force-new-deployment \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIV],securityGroups=[$GWSG],assignPublicIp=DISABLED}" >/dev/null

# 2. Default route via the NAT gateway.
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT" >/dev/null

# 3. HTTPS egress.
aws_local ec2 authorize-security-group-egress --group-id "$GWSG" \
  --ip-permissions 'IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}]' >/dev/null

# 4. Port 8080 from the load balancer's group only.
aws_local ec2 authorize-security-group-ingress --group-id "$GWSG" \
  --ip-permissions "IpProtocol=tcp,FromPort=8080,ToPort=8080,UserIdGroupPairs=[{GroupId=$ALBSG}]" >/dev/null
