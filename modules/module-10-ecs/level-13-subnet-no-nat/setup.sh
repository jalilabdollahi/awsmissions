#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.180.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lantern}]' --query Vpc.VpcId --output text)
PUB=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.180.1.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lantern-public}]' --query Subnet.SubnetId --output text)
PRIV=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.180.2.0/24 --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lantern-private}]' --query Subnet.SubnetId --output text)
IGW=$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC"
PUBRT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=lantern-public-rt}]' --query RouteTable.RouteTableId --output text)
PRIVRT=$(aws_local ec2 create-route-table --vpc-id "$VPC" \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=lantern-private-rt}]' --query RouteTable.RouteTableId --output text)
aws_local ec2 create-route --route-table-id "$PUBRT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$PUBRT" --subnet-id "$PUB" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$PRIVRT" --subnet-id "$PRIV" >/dev/null

SG=$(aws_local ec2 create-security-group --group-name lantern-sync-sg --description "lantern-sync" --vpc-id "$VPC" --query GroupId --output text)
cat > /tmp/awsm-lantern-$$.json <<'JSON'
{
  "family": "lantern-sync",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [{"name": "sync", "image": "alpine:3.21", "essential": true,
    "command": ["sh", "-c", "echo lantern-sync polling partner api; sleep 3600"]}]
}
JSON
aws_local ecs create-cluster --cluster-name lantern >/dev/null
aws_local ecs register-task-definition --cli-input-json "file:///tmp/awsm-lantern-$$.json" >/dev/null
rm -f /tmp/awsm-lantern-$$.json
aws_local ecs create-service --cluster lantern --service-name lantern-sync --task-definition lantern-sync:1 --desired-count 1 \
  --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$PRIV],securityGroups=[$SG],assignPublicIp=DISABLED}" >/dev/null
echo "lantern-sync runs in lantern-private, whose route table only has the local route."
