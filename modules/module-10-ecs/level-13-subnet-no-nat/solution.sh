#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=lantern --query 'Vpcs[0].VpcId' --output text)
PUB=$(aws_local ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=lantern-public --query 'Subnets[0].SubnetId' --output text)
PRIVRT=$(aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC" Name=tag:Name,Values=lantern-private-rt --query 'RouteTables[0].RouteTableId' --output text)
EIP=$(aws_local ec2 allocate-address --domain vpc --query AllocationId --output text)
NAT=$(aws_local ec2 create-nat-gateway --subnet-id "$PUB" --allocation-id "$EIP" --query NatGateway.NatGatewayId --output text)
aws_local ec2 wait nat-gateway-available --nat-gateway-ids "$NAT" 2>/dev/null || sleep 2
aws_local ec2 create-route --route-table-id "$PRIVRT" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT" >/dev/null
