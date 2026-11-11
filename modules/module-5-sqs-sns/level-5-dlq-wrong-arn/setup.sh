#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

dlq="$(aws_local sqs create-queue --queue-name mailroom-outbound-dlq --query QueueUrl --output text)"
out="$(aws_local sqs create-queue --queue-name mailroom-outbound \
  --attributes VisibilityTimeout=1 --query QueueUrl --output text)"

# Two jobs that were parked before the policy was edited by hand.
for who in anna@example.test ben@example.test; do
  aws_local sqs send-message --queue-url "$dlq" --message-body "{\"to\":\"$who\",\"status\":\"bounced\"}" >/dev/null
done

# The configuration as the player's workspace file describes it.
aws_local sqs set-queue-attributes --queue-url "$out" --attributes "file://$MISSION_DIR/workspace/redrive.json"

echo "mailroom-outbound has a redrive policy. Failed jobs still vanish."
