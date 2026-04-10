#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
timeout="$(aws_local lambda get-function-configuration --function-name mission-function --query Timeout --output text)"
[ "$timeout" = "60" ]
echo "success"
