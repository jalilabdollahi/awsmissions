#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

principal="$(aws_local iam get-role   --role-name cross-account-role   --query 'Role.AssumeRolePolicyDocument.Statement[0].Principal.AWS'   --output text 2>/dev/null || true)"

if [[ "$principal" == "arn:aws:iam::000000000000:root" ]]; then
  echo "cross-account-role now trusts the correct LocalStack account."
  exit 0
fi

echo "cross-account-role still trusts the wrong principal."
exit 1
