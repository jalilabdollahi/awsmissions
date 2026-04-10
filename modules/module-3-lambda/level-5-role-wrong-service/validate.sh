#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
service="$(aws_local iam get-role --role-name mission-lambda-role --query 'Role.AssumeRolePolicyDocument.Statement[0].Principal.Service' --output text)"
[ "$service" = "lambda.amazonaws.com" ]
echo "success"
