#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-group-policy --group-name empty-group --policy-name empty-group-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" == *"s3:GetObject"* && "$doc" == *"arn:aws:s3:::shared-bucket/*"* ]]; then
  echo "empty-group now has the required access policy."
  exit 0
fi

echo "empty-group still has no usable policy attached."
exit 1
