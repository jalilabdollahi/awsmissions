#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.100.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=fernhill}]' --query Vpc.VpcId --output text)
APP=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.100.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fh-app}]' --query Subnet.SubnetId --output text)
DATA=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.100.2.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=fh-data}]' --query Subnet.SubnetId --output text)
IGW=$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
RT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=fernhill-public}]' --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
# Mistake: the public table was associated with the data subnet.
aws_local ec2 associate-route-table --route-table-id "$RT" --subnet-id "$DATA" >/dev/null
echo "fernhill-public is attached to fh-data, not fh-app."
