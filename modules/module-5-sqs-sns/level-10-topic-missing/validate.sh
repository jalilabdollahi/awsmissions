#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:lighthouse-storm-warnings"
queue="$(aws_local sqs get-queue-url --queue-name harbor-radio-feed --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$queue" ]; then
  echo "The queue harbor-radio-feed is missing. It is the consumer; it should not be deleted."
  exit 1
fi

bulletin="gale-warning-$(date +%s)-$$"
if ! aws_local sns publish --topic-arn "$topic_arn" --message "$bulletin" >/dev/null 2>&1; then
  echo "Publishing to $topic_arn fails: the topic does not exist."
  exit 1
fi

got_it() {
  aws_local sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$bulletin"
}
if ! wait_for "bulletin delivery" 8 got_it; then
  echo "The topic accepts bulletins, but nothing arrives in harbor-radio-feed. A topic only forwards to its subscribers."
  exit 1
fi

echo "A bulletin published to lighthouse-storm-warnings reached harbor-radio-feed. The radio gateway is live again."
