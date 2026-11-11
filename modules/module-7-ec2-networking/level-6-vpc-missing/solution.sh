#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

BAD=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=meridian-prod --query 'Vpcs[0].VpcId' --output text)
aws_local ec2 delete-vpc --vpc-id "$BAD"
NEW=$(aws_local ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=meridian-prod}]' --query Vpc.VpcId --output text)
aws_local ec2 modify-vpc-attribute --vpc-id "$NEW" --enable-dns-hostnames
