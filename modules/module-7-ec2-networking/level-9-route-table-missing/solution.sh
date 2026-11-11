#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=harborview-prod --query 'Vpcs[0].VpcId' --output text)
IGW=$(aws_local ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC" --query 'InternetGateways[0].InternetGatewayId' --output text)
WEB=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=hv-web --query 'Subnets[0].SubnetId' --output text)
RT=$(aws_local ec2 create-route-table --vpc-id "$VPC" --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$RT" --subnet-id "$WEB" >/dev/null
