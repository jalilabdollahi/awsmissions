#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Only the consumer side survived the rollback.
aws_local sqs create-queue --queue-name harbor-radio-feed >/dev/null

echo "harbor-radio-feed is waiting, but the topic lighthouse-storm-warnings is gone."
