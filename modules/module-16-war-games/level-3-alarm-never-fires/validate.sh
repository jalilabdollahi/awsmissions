#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LG=/kp/settlement-api
STREAM=api-7f3c
PAGER_URL="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/kp-pager-inbox"
broken=0
echo "Monitoring chain check for kp-settlement-errors"

filter_json="$(aws_local logs describe-metric-filters --log-group-name "$LG" --output json 2>/dev/null || echo '{}')"
pattern="$(printf '%s' "$filter_json" | jq -r '.metricFilters[0].filterPattern // empty')"
alarm_json="$(aws_local cloudwatch describe-alarms --alarm-names kp-settlement-errors --query 'MetricAlarms[0]' --output json 2>/dev/null || echo null)"
if [ "$alarm_json" = "null" ] || [ "$(printf '%s' "$filter_json" | jq '.metricFilters | length')" = "0" ]; then
  echo "The metric filter or the alarm has been deleted. Repair them rather than recreating the monitoring from nothing."
  exit 1
fi

# Link 1: does the filter turn an ERROR line into a data point, and leave INFO alone?
hit_err="$(aws_local logs test-metric-filter --filter-pattern "$pattern" \
  --log-event-messages 'level=ERROR code=SETTLE_TIMEOUT batch=B-1 merchant=m-9' --query 'length(matches)' --output text 2>/dev/null || echo 0)"
hit_info="$(aws_local logs test-metric-filter --filter-pattern "$pattern" \
  --log-event-messages 'level=INFO code=SETTLED batch=B-2' --query 'length(matches)' --output text 2>/dev/null || echo 0)"
if [ "$hit_info" != "0" ]; then
  echo "[FAULT] link 1  the filter matches healthy INFO lines too - the alarm would page on normal traffic"
  broken=$((broken + 1))
elif [ "$hit_err" = "0" ]; then
  echo "[FAULT] link 1  a real ERROR line from the settlement API produces no metric data point"
  broken=$((broken + 1))
else
  echo "[ok]    link 1  ERROR lines become data points, INFO lines do not"
fi

# Link 2: is the alarm able to trip on a spike?
op="$(printf '%s' "$alarm_json" | jq -r '.ComparisonOperator')"
thr="$(printf '%s' "$alarm_json" | jq -r '.Threshold | floor')"
case "$op" in
  GreaterThanThreshold|GreaterThanOrEqualToThreshold)
    if [ "$thr" -lt 3 ] || [ "$thr" -gt 20 ]; then
      echo "[FAULT] link 2  alarm threshold $thr is outside what the postmortem asked for (5 errors in 10s)"
      broken=$((broken + 1))
    else
      echo "[ok]    link 2  alarm trips on a spike of errors"
    fi ;;
  *)
    echo "[FAULT] link 2  alarm is configured to trip when the error count is low, not when it spikes"
    broken=$((broken + 1)) ;;
esac

# Link 3: does ALARM state notify anybody?
actions="$(printf '%s' "$alarm_json" | jq -r '.AlarmActions | length')"
enabled="$(printf '%s' "$alarm_json" | jq -r '.ActionsEnabled')"
if [ "$actions" = "0" ] || [ "$enabled" != "true" ]; then
  echo "[FAULT] link 3  entering ALARM would not notify anyone"
  broken=$((broken + 1))
else
  echo "[ok]    link 3  alarm has a notification target"
fi

if [ "$broken" -gt 0 ]; then
  echo "$broken link(s) broken. Not generating a test burst until the static chain is sound."
  exit 1
fi

# Live fire: reset the alarm, drain the pager, then log a burst of errors.
aws_local sqs purge-queue --queue-url "$PAGER_URL" >/dev/null 2>&1 || true
aws_local cloudwatch set-alarm-state --alarm-name kp-settlement-errors --state-value OK --state-reason "validation reset" >/dev/null
sleep 2
now=$(( $(date +%s) * 1000 ))
events=()
for i in 1 2 3 4 5 6 7; do
  events+=("timestamp=$now,message=level=ERROR code=LEDGER_LOCKED batch=B-8$i merchant=m-$i")
done
events+=("timestamp=$now,message=level=INFO code=SETTLED batch=B-8000")
aws_local logs put-log-events --log-group-name "$LG" --log-stream-name "$STREAM" --log-events "${events[@]}" >/dev/null

paged() {
  aws_local sqs receive-message --queue-url "$PAGER_URL" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q 'kp-settlement-errors'
}
if ! wait_for "pager notification" 75 paged; then
  state="$(aws_local cloudwatch describe-alarms --alarm-names kp-settlement-errors --query 'MetricAlarms[0].StateValue' --output text)"
  echo "I logged seven ERROR lines and waited 75s: the alarm is '$state' and the pager queue is empty."
  echo "The static pieces look sane, so follow one data point all the way: log line -> metric -> alarm -> topic -> queue."
  exit 1
fi
echo "Seven errors went in; the alarm tripped and the pager queue got the page. Kestrel will never learn about an outage from Twitter again."
