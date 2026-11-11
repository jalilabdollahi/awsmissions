#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ALIVE=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=orbit-status Name=instance-state-name,Values=pending,running \
  --query 'Reservations[].Instances[].InstanceId' --output text)
COUNT=$(printf '%s' "$ALIVE" | wc -w | tr -d ' ')
if [ "$COUNT" != "1" ]; then
  echo "Expected exactly one live orbit-status instance, found $COUNT."
  exit 1
fi
IP=$(aws_local ec2 describe-instances --instance-ids "$ALIVE" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
if [ -z "$IP" ] || [ "$IP" = "None" ]; then
  echo "orbit-status ($ALIVE) still has no public IPv4 address. Remember: the subnet setting only affects instances launched afterwards."
  exit 1
fi
ASSOC=$(aws_local ec2 describe-addresses --filters Name=instance-id,Values="$ALIVE" --query 'Addresses[0].AssociationId' --output text 2>/dev/null || true)
if [ -z "$ASSOC" ] || [ "$ASSOC" = "None" ]; then
  echo "orbit-status has a public address ($IP) but it is an auto-assigned one, which changes after every stop/start. The partner firewall needs a stable address (Elastic IP)."
  exit 1
fi
echo "orbit-status is reachable at its Elastic IP $IP, which survives restarts."
