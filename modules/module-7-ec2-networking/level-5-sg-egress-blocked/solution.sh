#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

WORKER=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=parcel-worker-sg --query 'SecurityGroups[0].GroupId' --output text)
DB=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=parcel-db-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 authorize-security-group-egress --group-id "$WORKER" --protocol tcp --port 443 --cidr 0.0.0.0/0 >/dev/null
aws_local ec2 authorize-security-group-egress --group-id "$WORKER" --protocol tcp --port 5432 --source-group "$DB" >/dev/null
