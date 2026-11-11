#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

vpc="$(aws_local ec2 describe-vpcs --filters Name=tag:Name,Values=analytics-vpc --query 'Vpcs[0].VpcId' --output text)"
db="$(aws_local ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" Name=group-name,Values=warehouse-db-sg \
  --query 'SecurityGroups[0].GroupId' --output text)"
# Which group does the database already trust on 5432?
etl="$(aws_local ec2 describe-security-groups --group-ids "$db" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`5432`].UserIdGroupPairs[0].GroupId | [0]' --output text)"
subnets="$(aws_local lambda get-function-configuration --function-name warehouse-exporter \
  --query 'VpcConfig.SubnetIds' --output text | tr '\t' ',')"
aws_local lambda update-function-configuration --function-name warehouse-exporter \
  --vpc-config "SubnetIds=$subnets,SecurityGroupIds=$etl" >/dev/null
