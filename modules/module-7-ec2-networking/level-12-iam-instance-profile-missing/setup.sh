#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local s3 mb s3://ember-config >/dev/null
aws_local s3 mb s3://ember-billing >/dev/null
# Trust policy was copied from a Lambda role: wrong service principal.
aws_local iam create-role --role-name ember-app-role --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
aws_local iam put-role-policy --role-name ember-app-role --policy-name read-config --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject"],"Resource":"arn:aws:s3:::ember-config/*"}]}'

VPC=$(aws_local ec2 create-vpc --cidr-block 10.120.0.0/16 --query Vpc.VpcId --output text)
SUBNET=$(aws_local ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.120.1.0/24 --query Subnet.SubnetId --output text)
aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ember-api}]' >/dev/null
echo "ember-api is running with no instance profile; ember-app-role trusts the wrong service."
