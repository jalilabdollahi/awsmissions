#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
correct="$(aws_local s3api get-bucket-notification-configuration --bucket uploads-bucket --query 'LambdaFunctionConfigurations[0].LambdaFunctionArn' --output text)"
wrong="$(aws_local s3api get-bucket-notification-configuration --bucket wrong-bucket --query 'LambdaFunctionConfigurations[0].LambdaFunctionArn' --output text 2>/dev/null || true)"
[ "$correct" = "arn:aws:lambda:us-east-1:000000000000:function:mission-function" ]
[ -z "$wrong" ]
echo "success"
