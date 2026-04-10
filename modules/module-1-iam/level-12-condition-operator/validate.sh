#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

doc="$(aws_local iam get-role-policy --role-name prefix-reader-role --policy-name prefix-reader-policy --query 'PolicyDocument' --output json 2>/dev/null || true)"

if [[ "$doc" == *"StringLike"* && "$doc" != *"StringEquals"* ]]; then
  echo "prefix-reader-policy now uses StringLike for wildcard matching."
  exit 0
fi

echo "prefix-reader-policy still uses the wrong condition operator."
exit 1
