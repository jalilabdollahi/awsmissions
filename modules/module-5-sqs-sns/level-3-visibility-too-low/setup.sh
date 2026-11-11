#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

url="$(aws_local sqs create-queue --queue-name labelforge-jobs \
  --attributes VisibilityTimeout=2 --query QueueUrl --output text)"

for n in 1 2 3; do
  aws_local sqs send-message --queue-url "$url" \
    --message-body "{\"job\":\"label-$n\",\"carrier\":\"northwind-post\"}" >/dev/null
done

echo "labelforge-jobs has 3 labels waiting. Anything a worker picks up reappears after 2 seconds."
