#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

name=pylon-node-cpu-saturated
current() {
  aws_local cloudwatch describe-alarms --alarm-names "$name" \
    --query 'MetricAlarms[0].[StateValue,Namespace,MetricName,Period,Statistic]' --output text 2>/dev/null
}
info="$(current || true)"
if [ -z "$info" ] || [ "$info" = "None" ]; then
  echo "The alarm $name does not exist any more. Update it rather than deleting it."
  exit 1
fi
set -- $info
if [ "$2" != "Pylon/Compute" ] || [ "$3" != "NodeCpuPercent" ] || [ "$4" != "10" ] || [ "$5" != "Maximum" ]; then
  echo "The alarm now watches a different metric, period or statistic ($2 $3, period $4, $5). Only the threshold is wrong."
  exit 1
fi

wait_state() {
  local want="$1" secs="$2" n=0
  while [ "$n" -lt "$secs" ]; do
    [ "$(current | awk '{print $1}')" = "$want" ] && return 0
    sleep 1
    n=$((n + 1))
  done
  return 1
}

# Normal load: must not alarm.
aws_local cloudwatch put-metric-data --namespace Pylon/Compute --metric-name NodeCpuPercent --value 45
if ! wait_state OK 20; then
  echo "At 45% CPU the alarm is '$(current | awk '{print $1}')', expected OK."
  exit 1
fi

# Saturation: 97% must alarm.
sleep 2
aws_local cloudwatch put-metric-data --namespace Pylon/Compute --metric-name NodeCpuPercent --value 97
if ! wait_state ALARM 25; then
  echo "NodeCpuPercent reached 97 and the alarm did not fire. Look at its Threshold: CPU is a percentage between 0 and 100."
  exit 1
fi

echo "pylon-node-cpu-saturated stays OK at 45% and fires at 97%."
