#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.50.0.0/16 --query Vpc.VpcId --output text)
WORKER=$(aws_local ec2 create-security-group --group-name parcel-worker-sg --description "route optimizer" \
  --vpc-id "$VPC" --query GroupId --output text)
DB=$(aws_local ec2 create-security-group --group-name parcel-db-sg --description "parcel postgres" \
  --vpc-id "$VPC" --query GroupId --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$DB" --protocol tcp --port 5432 --source-group "$WORKER" >/dev/null

# The "hardening": strip the default allow-all egress rule.
aws_local ec2 revoke-security-group-egress --group-id "$WORKER" --ip-permissions \
  'IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]' >/dev/null
echo "parcel-worker-sg has no outbound rules at all."
