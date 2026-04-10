#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-user-policy   --user-name mission-deployer   --policy-name deployer-policy   --query 'PolicyDocument'   --output json 2>/dev/null || true)"

if [[ "$doc" == *"iam:PassRole"* && "$doc" == *"arn:aws:iam::000000000000:role/lambda-execution-role"* ]]; then
  echo "mission-deployer can now pass lambda-execution-role."
  exit 0
fi

echo "mission-deployer is still missing iam:PassRole on lambda-execution-role."
exit 1
