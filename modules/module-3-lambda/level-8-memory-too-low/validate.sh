#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
memory="$(aws_local lambda get-function-configuration --function-name mission-function --query MemorySize --output text)"
[ "$memory" = "512" ]
echo "success"
