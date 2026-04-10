#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

principal="$(aws_local iam get-role   --role-name lambda-execution-role   --query 'Role.AssumeRolePolicyDocument.Statement[0].Principal.Service'   --output text 2>/dev/null || true)"

if [[ "$principal" == "lambda.amazonaws.com" ]]; then
  echo "lambda-execution-role now trusts the Lambda service."
  exit 0
fi

echo "lambda-execution-role still has the wrong service principal."
exit 1
