#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

IID=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=orbit-status Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
ALLOC=$(aws_local ec2 allocate-address --domain vpc --query AllocationId --output text)
aws_local ec2 associate-address --instance-id "$IID" --allocation-id "$ALLOC" >/dev/null
