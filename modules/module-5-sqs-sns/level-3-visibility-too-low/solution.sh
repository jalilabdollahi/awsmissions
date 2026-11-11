#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Rendering takes up to 8s; 30s gives a comfortable margin.
aws_local sqs set-queue-attributes \
  --queue-url "$(aws_local sqs get-queue-url --queue-name labelforge-jobs --query QueueUrl --output text)" \
  --attributes VisibilityTimeout=30
