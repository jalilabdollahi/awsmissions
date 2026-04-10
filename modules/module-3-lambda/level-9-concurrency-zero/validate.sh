#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
value="$(aws_local lambda get-function-concurrency --function-name mission-function --query ReservedConcurrentExecutions --output text 2>/dev/null || true)"
[ "$value" != "0" ]
echo "success"
