#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local logs create-log-group --log-group-name /harvest/sensors
for n in 01 02 03 04 05 06; do
  aws_local logs create-log-stream --log-group-name /harvest/sensors --log-stream-name "field-gateway-$n"
done

echo "/harvest/sensors has streams field-gateway-01 .. 06. Gateway 07 has none."
