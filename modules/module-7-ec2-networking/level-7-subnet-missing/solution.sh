#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=brightwave-prod --query 'Vpcs[0].VpcId' --output text)
aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.70.1.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Tier,Value=public}]' >/dev/null
aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.70.2.0/24 --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Tier,Value=public}]' >/dev/null
