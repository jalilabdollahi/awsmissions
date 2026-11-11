#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

alarm=halcyon-db-connections-high
pager="$(aws_local sqs get-queue-url --queue-name halcyon-pager-app --query QueueUrl --output text 2>/dev/null || true)"
cfg="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" \
  --query 'MetricAlarms[0].[MetricName,Threshold,ComparisonOperator]' --output text 2>/dev/null || true)"
if [ -z "$cfg" ] || [ "$cfg" = "None" ]; then
  echo "The alarm $alarm is gone. Repair it instead of deleting it."
  exit 1
fi
if [ "$(printf '%s' "$cfg" | awk '{print $1, $2, $3}')" != "OpenConnections 150.0 GreaterThanThreshold" ]; then
  echo "The alarm's rule changed ($cfg). It should still fire when OpenConnections is above 150."
  exit 1
fi

enabled="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].ActionsEnabled' --output text)"
targets="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].AlarmActions' --output text)"
if [ "$enabled" != "True" ] && [ "$enabled" != "true" ]; then
  echo "The alarm's actions are disabled: it changes colour but does not run any action. (ActionsEnabled = $enabled)"
  exit 1
fi
case "$targets" in
  *halcyon-oncall) ;;
  *) echo "The alarm's action list ($targets) does not include the on-call topic halcyon-oncall."; exit 1 ;;
esac

# The incident: connections spike.
aws_local cloudwatch put-metric-data --namespace Halcyon/Database --metric-name OpenConnections --value 480
reached=""
for _ in $(seq 1 30); do
  reached="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text)"
  [ "$reached" = "ALARM" ] && break
  sleep 1
done
if [ "$reached" != "ALARM" ]; then
  echo "480 open connections did not put $alarm in ALARM (state: $reached)."
  exit 1
fi

arrived() {
  aws_local sqs receive-message --queue-url "$pager" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -qF "$alarm"
}
if ! wait_for "page delivery" 10 arrived; then
  echo "$alarm is in ALARM but the pager app received nothing. Is the notification wired to a topic the pager app is subscribed to?"
  exit 1
fi

echo "$alarm fired and the page reached the on-call pager app."
