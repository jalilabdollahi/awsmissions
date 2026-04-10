#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
role="$(aws_local lambda get-function-configuration --function-name mission-function --query Role --output text)"
aws_local iam get-role --role-name mission-lambda-role >/dev/null
[ "$role" = "arn:aws:iam::000000000000:role/mission-lambda-role" ]
echo "success"
