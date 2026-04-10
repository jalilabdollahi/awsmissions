#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
handler="$(aws_local lambda get-function-configuration --function-name mission-function --query Handler --output text)"
[ "$handler" = "index.lambda_handler" ]
echo "success"
