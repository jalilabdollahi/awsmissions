#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

OLD=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=atlas-bastion Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
SUBNET=$(aws_local ec2 describe-subnets --filters Name=tag:Name,Values=atlas-public --query 'Subnets[0].SubnetId' --output text)
SG=$(aws_local ec2 describe-security-groups --filters Name=group-name,Values=atlas-bastion-sg --query 'SecurityGroups[0].GroupId' --output text)
aws_local ec2 run-instances --image-id ami-alpine --instance-type t3.micro --subnet-id "$SUBNET" --security-group-ids "$SG" \
  --key-name platform-ops --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=atlas-bastion}]' >/dev/null
aws_local ec2 terminate-instances --instance-ids "$OLD" >/dev/null
