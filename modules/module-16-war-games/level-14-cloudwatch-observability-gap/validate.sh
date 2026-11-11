#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

LG=/aws/lambda/tf-checkout-fn
Q="$AWS_ENDPOINT_URL/${ACCOUNT_ID}/tf-oncall-inbox"
bad=0
echo "Checkout observability audit"

if ! aws_local lambda get-function --function-name tf-checkout-fn >/dev/null 2>&1; then
  echo "tf-checkout-fn is gone."
  exit 1
fi
alarm="$(aws_local cloudwatch describe-alarms --alarm-names tf-checkout-errors --query 'MetricAlarms[0]' --output json 2>/dev/null || echo null)"
if [ "$alarm" = "null" ]; then
  echo "The tf-checkout-errors alarm was deleted. Repair it, don't remove it."
  exit 1
fi

# Link 1: is there a filter on the log group the function actually writes to?
filt="$(aws_local logs describe-metric-filters --log-group-name "$LG" --output json 2>/dev/null | jq -c '.metricFilters[0] // empty')"
if [ -z "$filt" ]; then
  echo "[FAULT] link 1  nothing counts events from the function's log group ($LG)"
  bad=$((bad + 1))
else
  echo "[ok]    link 1  a metric filter is attached to $LG"
  pat="$(printf '%s' "$filt" | jq -r '.filterPattern')"
  hit_e="$(aws_local logs test-metric-filter --filter-pattern "$pat" --log-event-messages '{"level": "ERROR", "order": "o-1", "code": "CARD_DECLINED", "msg": "payment failed"}' --query 'length(matches)' --output text 2>/dev/null || echo 0)"
  hit_i="$(aws_local logs test-metric-filter --filter-pattern "$pat" --log-event-messages '{"level": "INFO", "order": "o-2", "msg": "charged"}' --query 'length(matches)' --output text 2>/dev/null || echo 0)"
  if [ "$hit_i" != "0" ]; then
    echo "[FAULT] link 2  the filter also counts successful checkouts"
    bad=$((bad + 1))
  elif [ "$hit_e" = "0" ]; then
    echo "[FAULT] link 2  a real failing-order log line does not match the filter's pattern"
    bad=$((bad + 1))
  else
    echo "[ok]    link 2  failing orders match, successful orders do not"
  fi
  fns="$(printf '%s' "$filt" | jq -r '.metricTransformations[0].metricNamespace + "|" + .metricTransformations[0].metricName')"
  ans="$(printf '%s' "$alarm" | jq -r '.Namespace + "|" + .MetricName')"
  if [ "$fns" = "$ans" ]; then
    echo "[ok]    link 3  the alarm watches the metric the filter produces"
  else
    echo "[FAULT] link 3  the filter produces '$fns' but the alarm watches '$ans'"
    bad=$((bad + 1))
  fi
fi

# Link 4: does the alarm's action reach a human?
acts="$(printf '%s' "$alarm" | jq -r '.AlarmActions[]?')"
reach=0
for t in $acts; do
  if aws_local sns list-subscriptions-by-topic --topic-arn "$t" --query "Subscriptions[?Endpoint=='arn:aws:sqs:us-east-1:${ACCOUNT_ID}:tf-oncall-inbox'] | length(@)" --output text 2>/dev/null | grep -q '^[1-9]'; then
    reach=1
  fi
done
if [ "$reach" -eq 1 ]; then
  echo "[ok]    link 4  the alarm action leads to the on-call queue"
else
  echo "[FAULT] link 4  nothing the alarm notifies leads to the on-call queue"
  bad=$((bad + 1))
fi
op="$(printf '%s' "$alarm" | jq -r '.ComparisonOperator')"
thr="$(printf '%s' "$alarm" | jq -r '.Threshold | floor')"
case "$op" in GreaterThanThreshold|GreaterThanOrEqualToThreshold) ;; *) echo "[FAULT] link 5  the alarm trips on low counts, not on a burst"; bad=$((bad + 1)) ;; esac
if [ "$thr" -lt 2 ] || [ "$thr" -gt 10 ]; then
  echo "[FAULT] link 5  the alarm threshold ($thr) would page on noise or never fire for a burst of 6"
  bad=$((bad + 1))
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad link(s) broken. Not triggering real failures yet."
  exit 1
fi

# Live fire.
aws_local sqs purge-queue --queue-url "$Q" >/dev/null 2>&1 || true
aws_local cloudwatch set-alarm-state --alarm-name tf-checkout-errors --state-value OK --state-reason "validation reset" >/dev/null
sleep 2
out="$(mktemp)"
for i in 1 2 3 4 5 6; do
  aws_local lambda invoke --function-name tf-checkout-fn --cli-binary-format raw-in-base64-out \
    --payload "{\"order\":\"o-v$i\",\"fail\":true}" "$out" >/dev/null
done
for i in 1 2; do
  aws_local lambda invoke --function-name tf-checkout-fn --cli-binary-format raw-in-base64-out \
    --payload "{\"order\":\"o-ok$i\"}" "$out" >/dev/null
done
rm -f "$out"
paged() {
  aws_local sqs receive-message --queue-url "$Q" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q 'tf-checkout-errors'
}
if ! wait_for "on-call page" 70 paged; then
  state="$(aws_local cloudwatch describe-alarms --alarm-names tf-checkout-errors --query 'MetricAlarms[0].StateValue' --output text)"
  echo "Six real failing checkouts were logged; the alarm is '$state' and tf-oncall-inbox is empty."
  echo "Everything looks wired, so follow one event end to end: log line -> metric -> alarm -> topic -> queue."
  exit 1
fi
echo "Six failing checkouts produced a page in tf-oncall-inbox. Next outage will not be a surprise."
