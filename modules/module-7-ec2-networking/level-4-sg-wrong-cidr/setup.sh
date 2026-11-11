#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

VPC=$(aws_local ec2 create-vpc --cidr-block 10.60.0.0/16 --query Vpc.VpcId --output text)
SG=$(aws_local ec2 create-security-group --group-name nw-bastion-sg --description "Northwind build bastion" \
  --vpc-id "$VPC" --query GroupId --output text)
# Old building range, still allowed.
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr 198.51.100.0/24 >/dev/null
# An unrelated, legitimate rule that must survive (monitoring from inside the VPC).
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 9100 --cidr 10.60.0.0/16 >/dev/null
echo "nw-bastion-sg only admits the old office range."
