#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.90.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=harborview-prod}]' --query Vpc.VpcId --output text)
aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.90.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hv-web}]' >/dev/null
aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.90.2.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=hv-db}]' >/dev/null
IGW=$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
echo "harborview-prod has an attached IGW and two subnets on the bare main route table."
