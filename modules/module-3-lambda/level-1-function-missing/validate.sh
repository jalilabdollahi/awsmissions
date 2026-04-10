#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local lambda get-function --function-name mission-function >/dev/null
echo "success"
