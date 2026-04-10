#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
runtime="$(aws_local lambda get-function-configuration --function-name mission-function --query Runtime --output text)"
[ "$runtime" = "python3.11" ]
echo "success"
