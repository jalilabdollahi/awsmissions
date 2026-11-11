#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-stream --log-group-name /harvest/sensors --log-stream-name field-gateway-07
