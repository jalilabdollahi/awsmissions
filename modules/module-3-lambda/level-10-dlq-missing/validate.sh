#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

FN=sms-notifier
QUEUE_URL="$(aws_local sqs get-queue-url --queue-name sms-failed-deliveries --query QueueUrl --output text)"
tag="$(date +%s)$$"
bad_id="fail-$tag"
good_id="ok-$tag"

cfg="$(aws_local lambda get-function-event-invoke-config --function-name "$FN" 2>/dev/null || true)"
if [ -z "$cfg" ]; then
  echo "The function has no asynchronous invocation settings at all any more; keep retries at 0 and add a failure destination."
  exit 1
fi
retries="$(printf '%s' "$cfg" | jq -r '.MaximumRetryAttempts // "unset"')"
if [ "$retries" != "0" ]; then
  echo "Retries are now '$retries' attempts. Retrying a text sends it twice, so MaximumRetryAttempts must stay 0."
  exit 1
fi
if ! printf '%s' "$cfg" | jq -e '.DestinationConfig.OnFailure.Destination' >/dev/null 2>&1; then
  echo "No failure destination is configured: failed events still vanish."
  exit 1
fi

# Fire a failing and a succeeding async event and watch the queue.
send() {
  aws_local lambda invoke --function-name "$FN" --invocation-type Event --cli-binary-format raw-in-base64-out \
    --payload "$1" /dev/null >/dev/null
}
send "{\"id\":\"$bad_id\",\"to\":\"not-a-phone-number\"}"
send "{\"id\":\"$good_id\",\"to\":\"+14155550123\"}"

found_bad=""; found_good=""
i=0
while [ "$i" -lt 12 ] && [ -z "$found_bad" ]; do
  msgs="$(aws_local sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 10 \
    --wait-time-seconds 2 --visibility-timeout 0 --query 'Messages[].Body' --output json 2>/dev/null || echo null)"
  if printf '%s' "$msgs" | jq -e --arg id "$bad_id" 'select(. != null) | map(fromjson) | any(.requestPayload.id == $id)' >/dev/null 2>&1; then
    found_bad=1
    printf '%s' "$msgs" > "${TMPDIR:-/tmp}/sms-validate-$tag.json"
  fi
  i=$((i + 1))
done
if [ -z "$found_bad" ]; then
  echo "A deliberately failing async invocation never showed up in sms-failed-deliveries within ~25 seconds."
  exit 1
fi
msgs="$(cat "${TMPDIR:-/tmp}/sms-validate-$tag.json")"; rm -f "${TMPDIR:-/tmp}/sms-validate-$tag.json"

if ! printf '%s' "$msgs" | jq -e --arg id "$bad_id" 'map(fromjson) | map(select(.requestPayload.id == $id)) | .[0].responsePayload.errorMessage | strings | test("invalid destination")' >/dev/null 2>&1; then
  echo "The failed event arrived without its error details; support needs to see why it failed."
  exit 1
fi
if printf '%s' "$msgs" | jq -e --arg id "$good_id" 'map(fromjson) | any(.requestPayload.id == $id)' >/dev/null 2>&1; then
  echo "A successful invocation also landed in the failure queue. Only failures belong there."
  exit 1
fi

echo "Failed texts now land in sms-failed-deliveries with their error, retries stay off, and successes stay out."
