#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

alarm=nimbus-data-volume-low-space
rule="$(aws_local cloudwatch describe-alarms --alarm-names "$alarm" \
  --query 'MetricAlarms[0].[MetricName,Threshold,Dimensions[0].Value]' --output text 2>/dev/null || true)"
if [ -z "$rule" ] || [ "$rule" = "None" ]; then
  echo "The alarm $alarm no longer exists; correct it instead."
  exit 1
fi
if [ "$rule" != "$(printf 'FreeSpaceGB\t10.0\tdata-01')" ]; then
  echo "The alarm's metric, dimension or threshold changed ($rule). Only its direction is wrong; keep the threshold at 10."
  exit 1
fi

read_state() {
  aws_local cloudwatch describe-alarms --alarm-names "$alarm" --query 'MetricAlarms[0].StateValue' --output text
}
publish_free_gb() {
  aws_local cloudwatch put-metric-data --namespace Nimbus/Storage --metric-name FreeSpaceGB \
    --dimensions VolumeId=data-01 --value "$1"
}

# A healthy volume: 55 GB free. Give the evaluator time to look at it (a
# stale state from earlier data must not decide), then require a calm OK.
publish_free_gb 55
sleep 18
t=0
settled=0
while [ "$t" -lt 15 ]; do
  if [ "$(read_state)" = "OK" ]; then
    settled=$((settled + 1))
    [ "$settled" -ge 3 ] && break
  else
    settled=0
  fi
  sleep 1
  t=$((t + 1))
done
if [ "$settled" -lt 3 ]; then
  echo "With 55 GB free the alarm is '$(read_state)'. It must only fire when less than 10 GB is left, and be OK otherwise."
  exit 1
fi

# A nearly full volume: 4 GB free.
sleep 3
publish_free_gb 4
t=0
while [ "$t" -lt 30 ]; do
  [ "$(read_state)" = "ALARM" ] && break
  sleep 1
  t=$((t + 1))
done
if [ "$(read_state)" != "ALARM" ]; then
  echo "Only 4 GB were free and the alarm did not fire (state: $(read_state))."
  exit 1
fi

echo "$alarm is quiet with 55 GB free and fires with 4 GB free."
