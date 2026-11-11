#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-configuration --function-name fx-rate-lookup \
  --environment 'Variables={RATES_TABLE=maple-fx-rates-prod,FX_PRECISION=4}' >/dev/null
