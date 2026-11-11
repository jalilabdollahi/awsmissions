#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=nw-bastion-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr 203.0.113.0/24 >/dev/null
aws_local ec2 revoke-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr 198.51.100.0/24 >/dev/null
