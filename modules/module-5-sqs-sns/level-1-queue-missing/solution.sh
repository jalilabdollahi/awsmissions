#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name harborline-orders \
  --attributes ReceiveMessageWaitTimeSeconds=10
