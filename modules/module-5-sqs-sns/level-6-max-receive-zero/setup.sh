#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local sqs create-queue --queue-name pinecrest-sms-dlq >/dev/null
sms="$(aws_local sqs create-queue --queue-name pinecrest-sms --attributes VisibilityTimeout=1 \
  --query QueueUrl --output text)"
aws_local sqs set-queue-attributes --queue-url "$sms" --attributes "file://$MISSION_DIR/workspace/redrive.json"

echo "pinecrest-sms parks a reminder after its very first failed attempt."
