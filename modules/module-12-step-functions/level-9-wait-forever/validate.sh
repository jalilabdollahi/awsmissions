#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SM="arn:aws:states:us-east-1:${ACCOUNT_ID}:stateMachine:halcyon-trial-reminder"
QUEUE="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/halcyon-reminders"
aws_local sqs purge-queue --queue-url "$QUEUE" >/dev/null 2>&1 || true

stamp_in() { # seconds from now -> ISO timestamp
  python3 -c 'import datetime as d, sys; print((d.datetime.now(d.timezone.utc)+d.timedelta(seconds=int(sys.argv[1]))).strftime("%Y-%m-%dT%H:%M:%SZ"))' "$1"
}
epoch_of() { python3 -c 'import datetime as d, sys; print(int(d.datetime.strptime(sys.argv[1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=d.timezone.utc).timestamp()))' "$1"; }

due_a="$(stamp_in 3)"
due_b="$(stamp_in 9)"
ex_a="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
  --input "{\"accountId\":\"V-EARLY\",\"remindAt\":\"$due_a\"}" --query executionArn --output text)"
ex_b="$(aws_local stepfunctions start-execution --state-machine-arn "$SM" \
  --input "{\"accountId\":\"V-LATE\",\"remindAt\":\"$due_b\"}" --query executionArn --output text)"
# Leave nothing waiting behind, whatever the outcome.
trap 'aws_local stepfunctions stop-execution --execution-arn "$ex_a" >/dev/null 2>&1 || true; aws_local stepfunctions stop-execution --execution-arn "$ex_b" >/dev/null 2>&1 || true' EXIT

state_of() { aws_local stepfunctions describe-execution --execution-arn "$1" --query status --output text; }
a_done() { [ "$(state_of "$ex_a")" != "RUNNING" ]; }
b_done() { [ "$(state_of "$ex_b")" != "RUNNING" ]; }

if ! wait_for "the early reminder" 20 a_done; then
  echo "The reminder due in 3 seconds was still waiting after 20 seconds. The Wait state does not follow remindAt."
  exit 1
fi
if [ "$(state_of "$ex_a")" != "SUCCEEDED" ]; then
  echo "The early execution ended as $(state_of "$ex_a"): $(aws_local stepfunctions describe-execution --execution-arn "$ex_a" --query 'error' --output text)"
  exit 1
fi
if ! wait_for "the late reminder" 25 b_done; then
  echo "The reminder due in 9 seconds never completed."
  exit 1
fi
if [ "$(state_of "$ex_b")" != "SUCCEEDED" ]; then
  echo "The late execution ended as $(state_of "$ex_b"): $(aws_local stepfunctions describe-execution --execution-arn "$ex_b" --query 'error' --output text)"
  exit 1
fi

stop_b="$(aws_local stepfunctions describe-execution --execution-arn "$ex_b" --query stopDate --output text)"
stop_epoch="$(python3 -c 'import datetime as d, sys; print(int(d.datetime.fromisoformat(sys.argv[1]).timestamp()))' "$stop_b")"
if [ "$stop_epoch" -lt $(( $(epoch_of "$due_b") - 1 )) ]; then
  echo "The reminder due at $due_b went out early. The workflow must wait until remindAt, not use a fixed delay."
  exit 1
fi

bodies="$(aws_local sqs receive-message --queue-url "$QUEUE" --max-number-of-messages 10 --wait-time-seconds 1 \
  --visibility-timeout 0 --query 'Messages[].Body' --output text)"
case "$bodies" in
  *V-EARLY*V-LATE*|*V-LATE*V-EARLY*) ;;
  *) echo "Both executions finished but the reminders did not both arrive on halcyon-reminders."; exit 1 ;;
esac

echo "Each reminder fired at its own remindAt, early ones early and late ones late."
