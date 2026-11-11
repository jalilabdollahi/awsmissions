#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

group=/talon/orders-api
alarm=talon-order-errors-high
pager="$(aws_local sqs get-queue-url --queue-name talon-pager --query QueueUrl --output text 2>/dev/null || true)"

if [ -z "$(aws_local logs describe-metric-filters --log-group-name "$group" --query 'metricFilters[0].filterName' --output text 2>/dev/null | grep -v None || true)" ]; then
  echo "The log group has no metric filter. Repair the existing filter."
  exit 1
fi
if [ -z "$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].AlarmName' --output text 2>/dev/null | grep -v None || true)" ]; then
  echo "The alarm $alarm does not exist."
  exit 1
fi

# Link 1: does the filter emit a metric for ERROR lines at all, and only those?
fmetric="$(aws_local logs describe-metric-filters --log-group-name "$group" \
  --query 'metricFilters[0].metricTransformations[0].[metricNamespace,metricName]' --output text)"
asked="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" \
  --query 'MetricAlarms[0].[Namespace,MetricName]' --output text)"

stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
now_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
events="$(mktemp)"
trap 'rm -f "$events"' EXIT
STAMP="$stamp" NOW="$now_ms" python3 - > "$events" <<'PY'
import json, os
t, n = os.environ["STAMP"], int(os.environ["NOW"])
lines = ["%s INFO order %d accepted" % (t, i) for i in range(6)]
lines += ["%s ERROR order %d payment gateway unreachable" % (t, i) for i in range(5)]
print(json.dumps([{"timestamp": n + i, "message": m} for i, m in enumerate(lines)]))
PY
aws_local logs put-log-events --log-group-name "$group" --log-stream-name api-1 \
  --log-events "file://$events" >/dev/null

# Link 2 and 3: wait for the alarm and for the page.
state=""
for _ in $(seq 1 40); do
  state="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text)"
  [ "$state" = "ALARM" ] && break
  sleep 1
done
if [ "$state" != "ALARM" ]; then
  if [ "$fmetric" != "$asked" ]; then
    echo "The alarm never fired after 5 ERROR lines. The metric filter publishes to [$fmetric] but the alarm watches [$asked]: these must be the same metric."
  else
    echo "The alarm never fired after 5 ERROR lines (state: $state), although filter and alarm name the same metric [$fmetric]. Does the filter really count the lines the API writes?"
  fi
  exit 1
fi

paged() {
  aws_local sqs receive-message --queue-url "$pager" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -qF 'NewStateValue\":\"ALARM'
}
if ! wait_for "page" 10 paged; then
  echo "The alarm went to ALARM but nothing reached the pager queue. Check the alarm's action."
  exit 1
fi

echo "ERROR lines in /talon/orders-api now travel through the filter and the alarm to the pager."
