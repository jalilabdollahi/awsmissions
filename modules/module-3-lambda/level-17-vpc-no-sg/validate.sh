#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
sg="$(aws_local lambda get-function-configuration --function-name mission-function --query 'VpcConfig.SecurityGroupIds[0]' --output text)"
[ "$sg" = "sg-12345678" ]
echo "success"
