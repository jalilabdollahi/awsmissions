#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

tagspec() { printf 'ResourceType=%s,Tags=[{Key=Name,Value=%s}]' "$1" "$2"; }

vpc="$(aws_local ec2 create-vpc --cidr-block 10.70.0.0/16 --tag-specifications "$(tagspec vpc analytics-vpc)" \
  --query Vpc.VpcId --output text)"
s1="$(aws_local ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.70.1.0/24 --availability-zone us-east-1a \
  --query Subnet.SubnetId --output text)"
s2="$(aws_local ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.70.2.0/24 --availability-zone us-east-1b \
  --query Subnet.SubnetId --output text)"

mksg() { aws_local ec2 create-security-group --group-name "$1" --description "$2" --vpc-id "$vpc" --query GroupId --output text; }
etl="$(mksg etl-clients-sg "jobs allowed to read the warehouse")"
bastion="$(mksg bastion-admin-sg "admin jump host access")"
db="$(mksg warehouse-db-sg "warehouse database firewall")"
mksg reporting-sg "BI dashboards (not yet allowed to the warehouse)" >/dev/null

# The database trusts exactly one client group, by reference.
aws_local ec2 authorize-security-group-ingress --group-id "$db" \
  --ip-permissions "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=$etl,Description=etl jobs}]" >/dev/null
aws_local ec2 authorize-security-group-ingress --group-id "$bastion" \
  --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=198.51.100.0/24,Description=office}]" >/dev/null

aws_local iam create-role --role-name warehouse-export-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
(cd "$MISSION_DIR/workspace" && zip -q "$stage/export.zip" export.mjs)
aws_local lambda create-function --function-name warehouse-exporter \
  --runtime nodejs20.x --handler export.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/warehouse-export-role" \
  --environment 'Variables={WAREHOUSE_HOST=warehouse.db.granite.example}' \
  --vpc-config "SubnetIds=$s1,$s2" \
  --zip-file "fileb://$stage/export.zip" >/dev/null

echo "warehouse-exporter sits in analytics-vpc subnets without any security group."
