#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy \
  --role-name lambda-basic-role \
  --policy-name lambda-basic-policy \
  --query 'PolicyDocument' \
  --output json 2>/dev/null || true)"

if [[ "$doc" == *"logs:CreateLogGroup"* && "$doc" == *"logs:CreateLogStream"* && "$doc" == *"logs:PutLogEvents"* ]]; then
  echo "lambda-basic-role now has an inline policy granting basic Lambda logging permissions."
  exit 0
fi

echo "lambda-basic-role still has no usable inline policy attached."
exit 1
