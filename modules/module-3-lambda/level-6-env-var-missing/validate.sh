#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
value="$(aws_local lambda get-function-configuration --function-name mission-function --query 'Environment.Variables.DATABASE_URL' --output text)"
[ "$value" = "postgres://mission-db" ]
echo "success"
