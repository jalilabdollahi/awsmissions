#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

rule="$(aws_local cloudwatch describe-alarms --alarm-types CompositeAlarm --alarm-names strata-api-unhealthy \
  --query 'CompositeAlarms[0].AlarmRule' --output text 2>/dev/null || true)"
if [ -z "$rule" ] || [ "$rule" = "None" ]; then
  echo "The composite alarm strata-api-unhealthy does not exist. Redefine it with put-composite-alarm."
  exit 1
fi
case "$rule" in
  *strata-api-errors*strata-api-latency*|*strata-api-latency*strata-api-errors*) ;;
  *) echo "The rule must keep combining both strata-api-errors and strata-api-latency."; exit 1 ;;
esac
acts="$(aws_local cloudwatch describe-alarms --alarm-types CompositeAlarm --alarm-names strata-api-unhealthy \
  --query 'CompositeAlarms[0].AlarmActions' --output text)"
case "$acts" in
  *strata-oncall) ;;
  *) echo "The composite no longer notifies strata-oncall. put-composite-alarm replaces the whole definition, so pass the alarm action again."; exit 1 ;;
esac

composite_state() {
  aws_local cloudwatch describe-alarms --alarm-types CompositeAlarm --alarm-names strata-api-unhealthy \
    --query 'CompositeAlarms[0].StateValue' --output text
}

# 1. Both children healthy: the composite must be quiet.
t=0
while [ "$t" -lt 25 ] && [ "$(composite_state)" != "OK" ]; do
  sleep 1
  t=$((t + 1))
done
if [ "$(composite_state)" != "OK" ]; then
  echo "Both child alarms are healthy and strata-api-unhealthy is '$(composite_state)'. Read the rule aloud: when exactly does it become true?"
  exit 1
fi
sleep 5
if [ "$(composite_state)" != "OK" ]; then
  echo "strata-api-unhealthy does not stay OK while its children are healthy."
  exit 1
fi

# 2. Only latency breaks: one failing child is enough.
aws_local cloudwatch put-metric-data --namespace Strata/Api --metric-name LatencyMs --value 1800
t=0
while [ "$t" -lt 35 ] && [ "$(composite_state)" != "ALARM" ]; do
  sleep 1
  t=$((t + 1))
done
if [ "$(composite_state)" != "ALARM" ]; then
  echo "Latency hit 1800 ms (strata-api-latency alarms) but strata-api-unhealthy stayed '$(composite_state)'."
  exit 1
fi

echo "strata-api-unhealthy is quiet while both checks are green and goes to ALARM as soon as one of them fails, with strata-oncall as its action."
