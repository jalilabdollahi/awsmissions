#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ORD=$(aws_local ec2 create-vpc --cidr-block 10.160.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=orders-vpc}]' --query Vpc.VpcId --output text)
BIL=$(aws_local ec2 create-vpc --cidr-block 10.161.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=billing-vpc}]' --query Vpc.VpcId --output text)
OSUB=$(aws_local ec2 create-subnet --vpc-id "$ORD" --cidr-block 10.160.1.0/24 --query Subnet.SubnetId --output text)
BSUB=$(aws_local ec2 create-subnet --vpc-id "$BIL" --cidr-block 10.161.1.0/24 --query Subnet.SubnetId --output text)
ORT=$(aws_local ec2 create-route-table --vpc-id "$ORD" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=orders-private}]' --query RouteTable.RouteTableId --output text)
BRT=$(aws_local ec2 create-route-table --vpc-id "$BIL" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=billing-private}]' --query RouteTable.RouteTableId --output text)
aws_local ec2 associate-route-table --route-table-id "$ORT" --subnet-id "$OSUB" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$BRT" --subnet-id "$BSUB" >/dev/null

DB=$(aws_local ec2 create-security-group --group-name billing-db-sg --description "billing postgres" --vpc-id "$BIL" --query GroupId --output text)
# Someone allowed the wrong neighbour range for the database port.
aws_local ec2 authorize-security-group-ingress --group-id "$DB" --protocol tcp --port 5432 --cidr 10.162.0.0/16 >/dev/null

aws_local ec2 create-vpc-peering-connection --vpc-id "$ORD" --peer-vpc-id "$BIL" \
  --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=orders-billing}]' >/dev/null
echo "The peering is requested but pending; no routes exist; the DB rule names the wrong range."
