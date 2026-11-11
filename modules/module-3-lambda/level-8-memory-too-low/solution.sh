#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-configuration --function-name tile-stitcher \
  --memory-size 512 >/dev/null
