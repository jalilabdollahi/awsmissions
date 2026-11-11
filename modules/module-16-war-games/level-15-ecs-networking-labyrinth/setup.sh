#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC="$(aws_local ec2 create-vpc --cidr-block 10.30.0.0/16 --query Vpc.VpcId --output text)"
aws_local ec2 create-tags --resources "$VPC" --tags Key=Name,Value=mt-vpc >/dev/null
PUB="$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.30.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)"
PRIV="$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.30.2.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)"
aws_local ec2 create-tags --resources "$PUB" --tags Key=Name,Value=mt-public-a >/dev/null
aws_local ec2 create-tags --resources "$PRIV" --tags Key=Name,Value=mt-private-a >/dev/null

IGW="$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)"
aws_local ec2 attach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC" >/dev/null
PUBRT="$(aws_local ec2 create-route-table --vpc-id "$VPC" --query RouteTable.RouteTableId --output text)"
aws_local ec2 create-route --route-table-id "$PUBRT" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$PUBRT" --subnet-id "$PUB" >/dev/null
EIP="$(aws_local ec2 allocate-address --domain vpc --query AllocationId --output text)"
NAT="$(aws_local ec2 create-nat-gateway --subnet-id "$PUB" --allocation-id "$EIP" --query NatGateway.NatGatewayId --output text)"
aws_local ec2 create-tags --resources "$NAT" --tags Key=Name,Value=mt-nat >/dev/null
# Private route table: created by hand, no default route.
PRIVRT="$(aws_local ec2 create-route-table --vpc-id "$VPC" --query RouteTable.RouteTableId --output text)"
aws_local ec2 associate-route-table --route-table-id "$PRIVRT" --subnet-id "$PRIV" >/dev/null

ALBSG="$(aws_local ec2 create-security-group --group-name mt-alb-sg --description "load balancer" --vpc-id "$VPC" --query GroupId --output text)"
aws_local ec2 authorize-security-group-ingress --group-id "$ALBSG" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null
GWSG="$(aws_local ec2 create-security-group --group-name mt-gateway-sg --description "mt-gateway tasks" --vpc-id "$VPC" --query GroupId --output text)"
# "Tightened": allow-all egress deleted, HTTP only; the ALB ingress rule was lost.
aws_local ec2 revoke-security-group-egress --group-id "$GWSG" --ip-permissions 'IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]' >/dev/null
aws_local ec2 authorize-security-group-egress --group-id "$GWSG" --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]' >/dev/null

aws_local ecs create-cluster --cluster-name mt-prod >/dev/null
aws_local ecs register-task-definition --family mt-gateway --network-mode awsvpc --requires-compatibilities FARGATE \
  --cpu 256 --memory 512 --container-definitions '[{"name":"gateway","image":"nginx:alpine","essential":true,"portMappings":[{"containerPort":8080,"protocol":"tcp"}]}]' >/dev/null
# Service definition copied from the old VPC: public subnet, public IP.
aws_local ecs create-service --cluster mt-prod --service-name mt-gateway --task-definition mt-gateway \
  --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PUB],securityGroups=[$GWSG],assignPublicIp=ENABLED}" >/dev/null

echo "INC-5561 is open: mt-gateway is running in the wrong place, with the wrong routes and rules."
