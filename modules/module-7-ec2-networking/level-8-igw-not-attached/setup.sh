#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.80.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=skyline-prod}]' --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.80.1.0/24 --query Subnet.SubnetId --output text)
IGW=$(aws_local ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=skyline-igw}]' \
  --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=legacy-igw}]' >/dev/null
RT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=skyline-public}]' --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$RT" --subnet-id "$SUBNET" >/dev/null

SG=$(aws_local ec2 create-security-group --group-name skyline-web --description "skyline web" --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null
aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" --security-group-ids "$SG" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=skyline-web}]' >/dev/null
echo "skyline-prod is built; the internet is not reachable."
