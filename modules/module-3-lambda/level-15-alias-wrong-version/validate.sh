#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
version="$(aws_local lambda get-alias --function-name mission-function --name production --query FunctionVersion --output text)"
[ "$version" = "\$LATEST" ]
echo "success"
