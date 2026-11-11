#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local kinesis increase-stream-retention-period --stream-name meter-reads --retention-period-hours 96 >/dev/null
