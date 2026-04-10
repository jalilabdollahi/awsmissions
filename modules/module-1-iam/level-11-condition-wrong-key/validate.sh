#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy --role-name guarded-role --policy-name guarded-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" == *"aws:SourceAccount"* && "$doc" != *"aws:sourceIp"* ]]; then
  echo "guarded-policy now uses the correct condition key."
  exit 0
fi

echo "guarded-policy still has the wrong condition key."
exit 1
