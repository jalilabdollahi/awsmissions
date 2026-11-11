#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=quillpad-web-sg \
  --query 'SecurityGroups[0].GroupId' --output text)
for port in 80 443; do
  aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port "$port" --cidr 0.0.0.0/0 >/dev/null
done
