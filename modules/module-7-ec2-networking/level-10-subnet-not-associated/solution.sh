#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

PUB=$(aws_local ec2 describe-route-tables --filters Name=tag:Name,Values=fernhill-public --query 'RouteTables[0].RouteTableId' --output text)
DATA=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=fh-data --query 'Subnets[0].SubnetId' --output text)
APP=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=fh-app --query 'Subnets[0].SubnetId' --output text)
ASSOC=$(aws_local ec2 describe-route-tables --route-table-ids "$PUB" \
  --query "RouteTables[0].Associations[?SubnetId=='$DATA'].RouteTableAssociationId|[0]" --output text)
aws_local ec2 disassociate-route-table --association-id "$ASSOC"
aws_local ec2 associate-route-table --route-table-id "$PUB" --subnet-id "$APP" >/dev/null
