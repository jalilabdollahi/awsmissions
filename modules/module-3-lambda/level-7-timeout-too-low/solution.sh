#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-configuration --function-name statement-renderer \
  --timeout 20 >/dev/null
