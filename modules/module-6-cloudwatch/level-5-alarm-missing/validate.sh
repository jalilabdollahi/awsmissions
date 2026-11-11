#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:meridian-oncall"
pager="$(aws_local sqs get-queue-url --queue-name meridian-oncall-pager --query QueueUrl --output text 2>/dev/null || true)"

names="$(aws_local cloudwatch describe-alarms \
  --query "MetricAlarms[?Namespace=='Meridian/Checkout' && MetricName=='P99LatencyMs'].AlarmName" \
  --output text 2>/dev/null || true)"
if [ -z "$names" ]; then
  echo "No alarm watches Meridian/Checkout P99LatencyMs yet."
  exit 1
fi
alarm="$(printf '%s' "$names" | awk '{print $1}')"

state_of() {
  aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text
}

# 1. Healthy traffic must not trip it.
aws_local cloudwatch put-metric-data --namespace Meridian/Checkout --metric-name P99LatencyMs \
  --value 310 --unit Milliseconds
i=0
while [ "$i" -lt 25 ]; do
  s="$(state_of)"
  [ "$s" = "OK" ] && break
  if [ "$s" = "ALARM" ]; then
    echo "The alarm '$alarm' fires at 310 ms. It should only fire above 800 ms."
    exit 1
  fi
  sleep 1
  i=$((i + 1))
done
if [ "$s" != "OK" ]; then
  echo "The alarm '$alarm' never settled to OK on healthy data (state: $s). Check how it treats the periods without data."
  exit 1
fi

# 2. An incident: 2.4 seconds.
sleep 2
aws_local cloudwatch put-metric-data --namespace Meridian/Checkout --metric-name P99LatencyMs \
  --value 2400 --unit Milliseconds
i=0
while [ "$i" -lt 30 ]; do
  [ "$(state_of)" = "ALARM" ] && break
  sleep 1
  i=$((i + 1))
done
if [ "$(state_of)" != "ALARM" ]; then
  echo "Latency hit 2400 ms but '$alarm' stayed out of ALARM. Check threshold and comparison operator."
  exit 1
fi

# 3. The page must really go out.
page_seen() {
  aws_local sqs receive-message --queue-url "$pager" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -qF 'NewStateValue\":\"ALARM'
}
if ! wait_for "page to arrive" 10 page_seen; then
  echo "'$alarm' went to ALARM but nothing was published to meridian-oncall (the on-call queue stayed empty). Add the topic as an alarm action."
  exit 1
fi

echo "'$alarm' stays quiet at 310 ms, fires at 2400 ms and pages meridian-oncall."
