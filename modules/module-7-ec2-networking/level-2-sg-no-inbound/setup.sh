#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.30.0.0/16 --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.30.1.0/24 --query Subnet.SubnetId --output text)
SG=$(aws_local ec2 create-security-group --group-name quillpad-web-sg --description "Quillpad web tier" \
  --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 create-tags --resources "$SG" --tags Key=Name,Value=quillpad-web-sg

aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" \
  --security-group-ids "$SG" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=quillpad-web}]' >/dev/null
echo "quillpad-web is running behind quillpad-web-sg, and readers are timing out."
