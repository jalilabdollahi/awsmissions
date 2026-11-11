#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=cobalt-nodes-sg --query 'SecurityGroups[0].GroupId' --output text)
for proto in tcp udp; do
  aws_local ec2 authorize-security-group-ingress --group-id "$SG" --protocol "$proto" --port 7946 --source-group "$SG" >/dev/null
done
