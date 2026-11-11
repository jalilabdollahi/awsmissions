#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda put-function-concurrency --function-name coupon-redeemer \
  --reserved-concurrent-executions 20 >/dev/null
