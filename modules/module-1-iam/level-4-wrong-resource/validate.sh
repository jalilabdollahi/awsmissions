#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

prod_url="$(aws_local sqs get-queue-url --queue-name orders-prod --query QueueUrl --output text 2>/dev/null || true)"
dlq_url="$(aws_local sqs get-queue-url --queue-name orders-dlq --query QueueUrl --output text 2>/dev/null || true)"
if [ -z "$prod_url" ] || [ -z "$dlq_url" ]; then
  echo "One of the queues (orders-prod, orders-dlq) is missing. Do not delete them; fix the policy."
  exit 1
fi

consumer() { aws_as_user orderflow-consumer "$@"; }

# Make sure there is exactly one fresh order waiting for the consumer.
aws_local sqs purge-queue --queue-url "$prod_url" >/dev/null 2>&1 || true
aws_local sqs send-message --queue-url "$prod_url" --message-body "{\"order\":\"check-$(date +%s)\"}" >/dev/null

if ! out="$(consumer sqs receive-message --queue-url "$prod_url" --max-number-of-messages 1 \
      --query 'Messages[0].ReceiptHandle' --output text 2>&1)"; then
  echo "orderflow-consumer still cannot receive from orders-prod."
  echo "SQS said: $(printf '%s' "$out" | tail -1)"
  echo "Compare the Resource of the consuming statement with the real ARN: aws sqs get-queue-attributes --queue-url <url> --attribute-names QueueArn"
  exit 1
fi
handle="$out"
if [ -z "$handle" ] || [ "$handle" = "None" ]; then
  echo "The call was allowed but no order came back. Try 'check' again in a few seconds."
  exit 1
fi
if ! out="$(consumer sqs delete-message --queue-url "$prod_url" --receipt-handle "$handle" 2>&1)"; then
  echo "Receiving works, but acknowledging (deleting) the message is denied: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

if ! out="$(consumer sqs send-message --queue-url "$dlq_url" --message-body poison 2>&1)"; then
  echo "orderflow-consumer cannot park a message in orders-dlq: $(printf '%s' "$out" | tail -1)"
  echo "The dead-letter statement points at an ARN that is not this queue either."
  exit 1
fi

# Over-fix guards.
if consumer sqs send-message --queue-url "$prod_url" --message-body forged >/dev/null 2>&1; then
  echo "The consumer can now inject orders into orders-prod. It should only consume from it."
  exit 1
fi
if consumer sqs receive-message --queue-url "$dlq_url" >/dev/null 2>&1; then
  echo "The consumer can read the dead-letter queue. It should only send to it."
  exit 1
fi
if consumer sqs purge-queue --queue-url "$prod_url" >/dev/null 2>&1; then
  echo "The consumer can purge orders-prod. That is far more than it needs."
  exit 1
fi

echo "orderflow-consumer drains orders-prod and parks poison in orders-dlq, and nothing else."
