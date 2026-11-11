#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:fernhill-reserve"

# Prints "<status> <number of Lambda attempts>" once the execution has finished.
reserve() {
  local input="$1" arn
  arn="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" --input "$input" \
    --query executionArn --output text)"
  settled() { [ "$(aws_local stepfunctions describe-execution --execution-arn "$arn" --query status --output text)" != "RUNNING" ]; }
  wait_for "reservation to finish" 50 settled || { echo "TIMEOUT 0"; return 0; }
  local status attempts
  status="$(aws_local stepfunctions describe-execution --execution-arn "$arn" --query status --output text)"
  attempts="$(aws_local stepfunctions get-execution-history --execution-arn "$arn" \
    --query 'length(events[?type==`LambdaFunctionScheduled`])' --output text)"
  echo "$status $attempts"
}

now="$(date +%s)"
locked_until=$((now + 5))
set -- $(reserve "{\"sku\":\"FG-TERRA-30\",\"qty\":2,\"lockedUntil\":$locked_until}")
if [ "$1" != "SUCCEEDED" ]; then
  echo "An order placed during a stock lock ended as $1 after $2 attempt(s). The lock lasts about 5 seconds and the workflow gave up too early."
  exit 1
fi
echo "The locked reservation succeeded after $2 attempt(s)."

set -- $(reserve '{"sku":"FG-GNOME-99","qty":1}')
if [ "$1" != "FAILED" ]; then
  echo "An order for an unknown SKU ended as $1; it should fail."
  exit 1
fi
if [ "$2" -gt 1 ]; then
  echo "The unknown SKU was attempted $2 times. Retrying an error that can never succeed wastes time and money: retry only what is transient."
  exit 1
fi

echo "Stock locks are ridden out with retries, and a bad SKU still fails straight away."
