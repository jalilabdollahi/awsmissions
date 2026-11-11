#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.130.0.0/16 --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.130.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=atlas-public}]' --query Subnet.SubnetId --output text)
SG=$(aws_local ec2 create-security-group --group-name atlas-bastion-sg --description "atlas bastion" \
  --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr 203.0.113.0/24 >/dev/null

aws_local ec2 create-key-pair --key-name platform-ops >/dev/null
aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" --security-group-ids "$SG" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=atlas-bastion}]' >/dev/null
echo "atlas-bastion is running without a key pair; platform-ops exists."
