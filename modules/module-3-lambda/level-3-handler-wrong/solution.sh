#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-configuration --function-name webhook-relay \
  --handler relay.sign >/dev/null
