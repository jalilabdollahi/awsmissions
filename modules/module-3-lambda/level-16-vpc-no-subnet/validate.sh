#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
subnet="$(aws_local lambda get-function-configuration --function-name mission-function --query 'VpcConfig.SubnetIds[0]' --output text)"
[ "$subnet" = "subnet-12345678" ]
echo "success"
