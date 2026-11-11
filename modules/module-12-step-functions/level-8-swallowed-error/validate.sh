#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:pinecrest-checkout"
receipts="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/pinecrest-receipts"
declined="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/pinecrest-declined"
aws_local sqs purge-queue --queue-url "$receipts" >/dev/null 2>&1 || true
aws_local sqs purge-queue --queue-url "$declined" >/dev/null 2>&1 || true

run_checkout() { # order token -> sets STATUS and ERR
  local ex
  ex="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
    --input "{\"orderId\":\"$1\",\"cardToken\":\"$2\",\"amount\":4500}" --query executionArn --output text)"
  over() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)" != "RUNNING" ]; }
  wait_for "checkout $1" 30 over
  STATUS="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query status --output text)"
  ERR="$(aws_local stepfunctions describe-execution --execution-arn "$ex" --query 'error' --output text)"
}

queue_text() { # queue url -> all bodies on one line
  aws_local sqs receive-message --queue-url "$1" --max-number-of-messages 10 --wait-time-seconds 1 \
    --visibility-timeout 0 --query 'Messages[].Body' --output text 2>/dev/null || true
}

tag="$(date +%s)"

# 1. A paid order still flows through to a receipt.
run_checkout "PT-$tag-paid" tok_ok
if [ "$STATUS" != "SUCCEEDED" ]; then
  echo "A paid order ended as $STATUS ($ERR). Normal payments must keep succeeding."
  exit 1
fi
case "$(queue_text "$receipts")" in *"PT-$tag-paid"*) ;; *) echo "A paid order produced no receipt on pinecrest-receipts."; exit 1 ;; esac
case "$(queue_text "$declined")" in *"PT-$tag-paid"*) echo "A paid order generated a decline notice."; exit 1 ;; esac

# 2. A declined card must be reported and must fail the execution.
run_checkout "PT-$tag-nsf" tok_declined
if [ "$STATUS" = "SUCCEEDED" ]; then
  echo "A declined card still ends as SUCCEEDED. Finance cannot trust the dashboard while errors are reported as success."
  exit 1
fi
if [ "$STATUS" != "FAILED" ]; then
  echo "The declined order ended as $STATUS; it should end FAILED."
  exit 1
fi
notice="$(queue_text "$declined")"
case "$notice" in
  *"PT-$tag-nsf"*) ;;
  *) echo "The execution failed, but the customer was not told: no message with the orderId arrived on pinecrest-declined."; exit 1 ;;
esac
case "$notice" in
  *CardDeclined*|*"insufficient funds"*) ;;
  *) echo "The decline notice does not say why the payment failed. Include the error that was caught."; exit 1 ;;
esac
case "$(queue_text "$receipts")" in *"PT-$tag-nsf"*) echo "A receipt was sent for an unpaid order."; exit 1 ;; esac

echo "Declines now notify the customer and fail the execution; paid orders still get receipts."
