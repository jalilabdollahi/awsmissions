#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The re-deploy created the wrong name; the real one was never created.
aws_local sqs create-queue --queue-name harborline-order >/dev/null

echo "harborline-order exists. harborline-orders does not. The intake service keeps failing."
