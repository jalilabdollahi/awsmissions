#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://quartz-exports >/dev/null
aws_local s3 mb s3://competitor-data >/dev/null

VPC=$(aws_local ec2 create-vpc --cidr-block 10.170.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=quartz-vpc}]' --query Vpc.VpcId --output text)
PUBSUB=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.170.1.0/24 --query Subnet.SubnetId --output text)
PRIVSUB=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.170.2.0/24 --query Subnet.SubnetId --output text)
IGW=$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
PUBRT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=quartz-public}]' --query RouteTable.RouteTableId --output text)
PRIVRT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=quartz-private}]' --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$PUBRT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$PUBRT" --subnet-id "$PUBSUB" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$PRIVRT" --subnet-id "$PRIVSUB" >/dev/null

aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$PRIVSUB" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=quartz-batch}]' >/dev/null
echo "quartz-batch sits in a private subnet with no way to S3."
