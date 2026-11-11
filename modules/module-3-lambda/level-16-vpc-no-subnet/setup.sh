#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tag() { printf 'ResourceType=%s,Tags=[{Key=Name,Value=%s}]' "$1" "$2"; }

vpc="$(aws_local ec2 create-vpc --cidr-block 10.50.0.0/16 --tag-specifications "$(tag vpc orders-vpc)" \
  --query Vpc.VpcId --output text)"
igw="$(aws_local ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)"
aws_local ec2 attach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"

sub() { # cidr az name
  aws_local ec2 create-subnet --vpc-id "$vpc" --cidr-block "$1" --availability-zone "$2" \
    --tag-specifications "$(tag subnet "$3")" --query Subnet.SubnetId --output text
}
sub 10.50.1.0/24 us-east-1a orders-app-a >/dev/null
sub 10.50.2.0/24 us-east-1b orders-app-b >/dev/null
sub 10.50.3.0/24 us-east-1c orders-app-c >/dev/null
edge="$(sub 10.50.100.0/24 us-east-1a orders-edge-a)"

# Only the edge subnet routes to the internet gateway.
rtb="$(aws_local ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)"
aws_local ec2 create-route --route-table-id "$rtb" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" >/dev/null
aws_local ec2 associate-route-table --route-table-id "$rtb" --subnet-id "$edge" >/dev/null

sg="$(aws_local ec2 create-security-group --group-name order-sync-sg --description "order-sync function" \
  --vpc-id "$vpc" --query GroupId --output text)"
dbsg="$(aws_local ec2 create-security-group --group-name orders-db-sg --description "orders database" \
  --vpc-id "$vpc" --query GroupId --output text)"
aws_local ec2 authorize-security-group-ingress --group-id "$dbsg" \
  --ip-permissions "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=$sg}]" >/dev/null

aws_local iam create-role --role-name order-sync-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/sync.zip" sync.py)

# The refactoring dropped the subnets but kept the security group.
aws_local lambda create-function --function-name order-sync \
  --runtime python3.12 --handler sync.run \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/order-sync-role" \
  --environment 'Variables={ORDERS_DB_HOST=orders-db.internal.orbit-retail.example}' \
  --vpc-config "SecurityGroupIds=$sg" \
  --zip-file "fileb://$stage/sync.zip" >/dev/null

echo "order-sync has a security group from orders-vpc but no subnets."
