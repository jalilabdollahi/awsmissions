#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group=/lumen/store-gateway
if ! aws_local iam get-user --user-name lumen-shipper >/dev/null 2>&1; then
  echo "The user lumen-shipper no longer exists."
  exit 1
fi

stream="store-$(date +%s)-$$"
if ! out="$(aws_as_user lumen-shipper logs create-log-stream --log-group-name "$group" --log-stream-name "$stream" 2>&1)"; then
  echo "lumen-shipper can no longer create log streams: $(printf '%s' "$out" | tail -1)"
  exit 1
fi

line="till-closed-$(date +%s)-$$"
now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
batch="$(mktemp)"
trap 'rm -f "$batch"' EXIT
printf '[{"timestamp":%s,"message":"%s"}]' "$now_ms" "$line" > "$batch"
if ! out="$(aws_as_user lumen-shipper logs put-log-events --log-group-name "$group" --log-stream-name "$stream" \
  --log-events "file://$batch" 2>&1)"; then
  echo "lumen-shipper still cannot upload log events: $(printf '%s' "$out" | tail -1)"
  exit 1
fi
stored() {
  aws_local logs get-log-events --log-group-name "$group" --log-stream-name "$stream" \
    --query 'events[].message' --output text 2>/dev/null | grep -qF "$line"
}
if ! wait_for "event stored" 6 stored; then
  echo "The upload was accepted but the event is not in the stream."
  exit 1
fi

if aws_as_user lumen-shipper logs delete-log-group --log-group-name "$group" >/dev/null 2>&1; then
  echo "lumen-shipper can delete the log group. A log shipper must only write, so drop broad permissions such as logs:* ."
  exit 1
fi
if aws_as_user lumen-shipper logs put-retention-policy --log-group-name "$group" --retention-in-days 1 >/dev/null 2>&1; then
  echo "lumen-shipper can change the group's retention (and so destroy history). Remove permissions the agent does not need."
  exit 1
fi
if ! aws_local logs describe-log-groups --log-group-name-prefix "$group" --query 'logGroups[0].logGroupName' --output text | grep -q lumen; then
  echo "The log group is gone."
  exit 1
fi

echo "lumen-shipper can create streams and ship events, and cannot delete or reconfigure the group."
