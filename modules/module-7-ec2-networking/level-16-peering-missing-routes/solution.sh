#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

PCX=$(aws_local ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text)
aws_local ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$PCX" >/dev/null
rt() {
  local vpc
  vpc=$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values="$1" --query 'Vpcs[0].VpcId' --output text)
  aws_local ec2 describe-route-tables --filters Name=vpc-id,Values="$vpc" Name=tag:Name,Values="$2" --query 'RouteTables[0].RouteTableId' --output text
}
aws_local ec2 create-route --route-table-id "$(rt orders-vpc orders-private)" --destination-cidr-block 10.161.0.0/16 --vpc-peering-connection-id "$PCX" >/dev/null
aws_local ec2 create-route --route-table-id "$(rt billing-vpc billing-private)" --destination-cidr-block 10.160.0.0/16 --vpc-peering-connection-id "$PCX" >/dev/null

DB=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=billing-db-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$DB" --protocol tcp --port 5432 --cidr 10.160.0.0/16 >/dev/null
aws_local ec2 revoke-security-group-ingress --group-id "$DB" --protocol tcp --port 5432 --cidr 10.162.0.0/16 >/dev/null
