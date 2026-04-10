#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
layer="$(aws_local lambda get-function-configuration --function-name mission-function --query 'Layers[0].Arn' --output text)"
case "$layer" in
  arn:aws:lambda:us-east-1:000000000000:layer:mission-utils:*)
    echo "success"
    ;;
  *)
    exit 1
    ;;
esac
