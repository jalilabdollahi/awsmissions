#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group="/swiftpost/checkout-api"
found="$(aws_local logs describe-log-groups --log-group-name-prefix "$group" \
  --query "logGroups[?logGroupName=='$group'].logGroupName" --output text 2>/dev/null || true)"
if [ -z "$found" ]; then
  echo "The log group $group does not exist. The container's log driver can create streams but never groups."
  exit 1
fi

# Do what the container's log driver does: create a stream, flush two lines.
stream="container-$(date +%s)-$$"
token="checkout-started-$(date +%s)-$$"
if ! aws_local logs create-log-stream --log-group-name "$group" --log-stream-name "$stream" >/dev/null 2>&1; then
  echo "A container cannot create its log stream in $group."
  exit 1
fi
now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
events="$(mktemp)"
trap 'rm -f "$events"' EXIT
printf '[{"timestamp":%s,"message":"%s"},{"timestamp":%s,"message":"order accepted"}]' \
  "$now_ms" "$token" "$now_ms" > "$events"
if ! aws_local logs put-log-events --log-group-name "$group" --log-stream-name "$stream" \
  --log-events "file://$events" >/dev/null 2>&1; then
  echo "put-log-events into $group/$stream failed."
  exit 1
fi

has_line() {
  aws_local logs filter-log-events --log-group-name "$group" --filter-pattern "\"$token\"" \
    --query 'events[].message' --output text 2>/dev/null | grep -q "$token"
}
if ! wait_for "log line to be searchable" 6 has_line; then
  echo "The log line was accepted but cannot be read back from $group."
  exit 1
fi

echo "The checkout API can create streams in $group and its log lines are searchable again."
