#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

vpc="$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=orders-vpc --query 'Vpcs[0].VpcId' --output text)"
# Private subnets are the "app" ones; the "edge" subnet has the internet route.
ids="$(aws_local ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" "Name=tag:Name,Values=orders-app-a,orders-app-b" \
  --query 'Subnets[].SubnetId' --output text | tr '\t' ',')"
sg="$(aws_local lambda get-function-configuration --function-name order-sync \
  --query 'VpcConfig.SecurityGroupIds[0]' --output text)"
aws_local lambda update-function-configuration --function-name order-sync \
  --vpc-config "SubnetIds=$ids,SecurityGroupIds=$sg" >/dev/null
