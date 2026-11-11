#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=skyline-prod --query 'Vpcs[0].VpcId' --output text)
IGW=$(aws_local ec2 describe-internet-gateways --filters Name=tag:Name,Values=skyline-igw --query 'InternetGateways[0].InternetGatewayId' --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
