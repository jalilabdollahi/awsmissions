#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Orbit's production network: one VPC, one routed public subnet, one status host.
read -r VPC IGW <<EOT
$(aws_local ec2 create-vpc --cidr-block 10.140.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=orbit-prod}]' --query Vpc.VpcId --output text) $(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
EOT
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
RT=$(aws_local ec2 create-route-table --vpc-id "$VPC" --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$RT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null

SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.140.1.0/24 --query Subnet.SubnetId --output text)
aws_local ec2 modify-subnet-attribute --subnet-id "$SUBNET" --no-map-public-ip-on-launch
aws_local ec2 associate-route-table --route-table-id "$RT" --subnet-id "$SUBNET" >/dev/null

SG=$(aws_local ec2 create-security-group --group-name orbit-status-sg --description "status page" --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null
aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" --security-group-ids "$SG" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=orbit-status}]' >/dev/null
echo "orbit-status runs in a fully routed public subnet with only a private IP."
