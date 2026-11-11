#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

PORT=$(aws_local ssm get-parameter --name /ledger/api/listen-port --query Parameter.Value --output text)
ALB_SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=ledger-alb-sg --query 'SecurityGroups[0].GroupId' --output text)
API_SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=ledger-api-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 authorize-security-group-ingress --group-id "$API_SG" --protocol tcp --port "$PORT" --source-group "$ALB_SG" >/dev/null
aws_local ec2 revoke-security-group-ingress --group-id "$API_SG" --protocol tcp --port 8080 --source-group "$ALB_SG" >/dev/null
