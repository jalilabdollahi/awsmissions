#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.150.0.0/16 --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.150.1.0/24 --query Subnet.SubnetId --output text)
MON=$(aws_local ec2 create-security-group --group-name cobalt-monitor-sg --description "monitoring" --vpc-id "$VPC" --query GroupId --output text)
NODES=$(aws_local ec2 create-security-group --group-name cobalt-nodes-sg --description "cache nodes" --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$NODES" --protocol tcp --port 9100 --source-group "$MON" >/dev/null

for n in 1 2 3; do
  aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" --security-group-ids "$NODES" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cobalt-node-$n}]" >/dev/null
done
echo "Three cobalt nodes share cobalt-nodes-sg; only monitoring can reach them."
