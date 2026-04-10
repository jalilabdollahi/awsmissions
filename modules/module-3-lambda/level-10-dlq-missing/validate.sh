#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
target="$(aws_local lambda get-function-configuration --function-name mission-function --query 'DeadLetterConfig.TargetArn' --output text)"
[ "$target" = "arn:aws:sqs:us-east-1:000000000000:mission-dlq" ]
echo "success"
