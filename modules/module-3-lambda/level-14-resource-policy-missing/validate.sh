#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
policy="$(aws_local lambda get-policy --function-name mission-function --query 'Policy' --output text)"
case "$policy" in
  *s3.amazonaws.com*)
    echo "success"
    ;;
  *)
    exit 1
    ;;
esac
