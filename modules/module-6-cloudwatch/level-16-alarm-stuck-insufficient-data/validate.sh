#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

name=vesper-backup-failed
rule="$(aws_local cloudwatch describe-alarms --alarm-names "$name" \
  --query 'MetricAlarms[0].[Namespace,MetricName,Statistic,Threshold]' --output text 2>/dev/null || true)"
if [ -z "$rule" ] || [ "$rule" = "None" ]; then
  echo "The alarm $name does not exist. Repair it instead of removing it."
  exit 1
fi
if [ "$rule" != "$(printf 'Vesper/Backup\tBackupFailures\tSum\t1.0')" ]; then
  echo "The alarm's metric, statistic or threshold changed ($rule). Only its handling of missing data is wrong."
  exit 1
fi

current() { aws_local cloudwatch describe-alarms --alarm-names "$name" --query 'MetricAlarms[0].StateValue' --output text; }

# No failures are published in this phase: a quiet night must read as OK.
i=0
while [ "$i" -lt 25 ] && [ "$(current)" != "OK" ]; do
  sleep 1
  i=$((i + 1))
done
if [ "$(current)" != "OK" ]; then
  mode="$(aws_local cloudwatch describe-alarms --alarm-names "$name" --query 'MetricAlarms[0].TreatMissingData' --output text)"
  echo "No failures were published and the alarm is '$(current)'. With TreatMissingData=$mode, periods without datapoints do not count as healthy."
  exit 1
fi

# A real failure still has to raise it.
aws_local cloudwatch put-metric-data --namespace Vesper/Backup --metric-name BackupFailures --value 1
i=0
while [ "$i" -lt 30 ] && [ "$(current)" != "ALARM" ]; do
  sleep 1
  i=$((i + 1))
done
if [ "$(current)" != "ALARM" ]; then
  echo "A failure was published but the alarm is still '$(current)'."
  exit 1
fi

echo "$name is OK on quiet nights and fires on a failure."
