#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
arn="$(aws_local s3api get-bucket-notification-configuration --bucket uploads-bucket --query 'LambdaFunctionConfigurations[0].LambdaFunctionArn' --output text)"
event="$(aws_local s3api get-bucket-notification-configuration --bucket uploads-bucket --query 'LambdaFunctionConfigurations[0].Events[0]' --output text)"
[ "$arn" = "arn:aws:lambda:us-east-1:000000000000:function:mission-function" ]
[ "$event" = "s3:ObjectCreated:*" ]
echo "success"
