#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local lambda update-function-configuration --function-name thermo-ingest \
  --environment 'Variables={STREAM_NAME=thermowave-readings,FIRMWARE_CHANNEL=stable}' >/dev/null
