#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=tindle-prod}]' \
  --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=tindle-public-a}]' \
  --query Subnet.SubnetId --output text)
IGW=$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
RT=$(aws_local ec2 create-route-table --vpc-id "$VPC" --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$RT" --subnet-id "$SUBNET" >/dev/null

# A decoy group that already exists in the *default* VPC (wrong VPC for this launch).
aws_local ec2 create-security-group --group-name tindle-web --description "old storefront web (default VPC)" \
  --vpc-id vpc-default-us-east-1 >/dev/null

echo "tindle-prod is up. launch-web.sh still points at a security group that was cleaned up."
