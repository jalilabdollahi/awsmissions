#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-user-policy --user-name switcher-user --policy-name switcher-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" == *"sts:AssumeRole"* && "$doc" == *"arn:aws:iam::000000000000:role/target-role"* ]]; then
  echo "switcher-user can now assume target-role."
  exit 0
fi

echo "switcher-user is still missing sts:AssumeRole on target-role."
exit 1
