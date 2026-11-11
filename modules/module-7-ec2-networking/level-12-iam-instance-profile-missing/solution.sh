#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local iam update-assume-role-policy --role-name ember-app-role --policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws_local iam create-instance-profile --instance-profile-name ember-app-profile >/dev/null
aws_local iam add-role-to-instance-profile --instance-profile-name ember-app-profile --role-name ember-app-role
IID=$(aws_local ec2 describe-instances --filters Name=tag:Name,Values=ember-api Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws_local ec2 associate-iam-instance-profile --instance-id "$IID" --iam-instance-profile Name=ember-app-profile >/dev/null
