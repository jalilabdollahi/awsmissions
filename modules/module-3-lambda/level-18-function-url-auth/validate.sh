#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
auth="$(aws_local lambda get-function-url-config --function-name mission-function --query AuthType --output text)"
[ "$auth" = "NONE" ]
echo "success"
