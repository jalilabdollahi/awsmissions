#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

alarm=brightside-bounce-spike
rule="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" \
  --query 'MetricAlarms[0].[Namespace,MetricName,Statistic,Threshold,ComparisonOperator,Period,EvaluationPeriods]' --output text 2>/dev/null || true)"
if [ -z "$rule" ] || [ "$rule" = "None" ]; then
  echo "The alarm $alarm is gone. Fix it rather than deleting it."
  exit 1
fi
period="$(printf '%s' "$rule" | awk '{print $6}')"
if [ "$(printf '%s' "$rule" | awk '{print $1, $2, $3, $4, $5}')" != "Brightside/Mail BouncedMessages Sum 50.0 GreaterThanOrEqualToThreshold" ]; then
  echo "Metric, statistic, threshold or comparison changed ($rule). Only how fast the alarm looks at the data should change."
  exit 1
fi

evals="$(printf '%s' "$rule" | awk '{print $7}')"
window=$(( ${period%.*} * ${evals%.*} ))
if [ "$window" -gt 60 ]; then
  echo "$alarm needs ${evals} period(s) of ${period}s = ${window}s of data before it can change state. Bounces must page within a minute."
  exit 1
fi

# The alarm must still really fire on a burst.
for _ in $(seq 1 20); do
  [ "$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text)" != "INSUFFICIENT_DATA" ] && break
  sleep 1
done
burst_at="$(date +%s)"
aws_local cloudwatch put-metric-data --namespace Brightside/Mail --metric-name BouncedMessages --value 300

now_state=""
while [ "$(( $(date +%s) - burst_at ))" -lt 90 ]; do
  now_state="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text)"
  if [ "$now_state" = "ALARM" ]; then
    echo "$alarm now judges a ${window}s window and went to ALARM $(( $(date +%s) - burst_at ))s after the burst."
    exit 0
  fi
  sleep 2
done

echo "The window is short enough, but 300 bounces did not move $alarm to ALARM (still '$now_state'). Check that the alarm still watches the bounce metric."
exit 1
