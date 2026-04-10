#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy --role-name home-reader-role --policy-name home-reader-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" == *'"Version":"2012-10-17"'* ]]; then
  echo "home-reader-policy now includes the required Version field."
  exit 0
fi

echo "home-reader-policy is still missing the Version field."
exit 1
