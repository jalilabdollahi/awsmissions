#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

TASK=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=slate-task-sg --query 'SecurityGroups[0].GroupId' --output text)
VPCE=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=slate-vpce-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 authorize-security-group-egress --group-id "$TASK" --protocol tcp --port 443 --source-group "$VPCE" >/dev/null
aws_local ec2 authorize-security-group-ingress --group-id "$VPCE" --protocol tcp --port 443 --source-group "$TASK" >/dev/null
aws_local ec2 revoke-security-group-ingress --group-id "$VPCE" --protocol tcp --port 443 --cidr 10.200.99.0/24 >/dev/null
