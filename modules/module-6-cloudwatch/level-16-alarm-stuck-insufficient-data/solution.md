# Solution

With `TreatMissingData: missing`, an evaluation period with no datapoint is simply skipped, and if there is nothing to evaluate the alarm stays in `INSUFFICIENT_DATA`. For a metric that is only published on failure, "no data" means "all good", which is what `notBreaching` expresses.

```bash
aws cloudwatch describe-alarms --alarm-names vesper-backup-failed \
  --query 'MetricAlarms[0].[StateValue,StateReason,TreatMissingData]'
```

Change it in `alarm.json` and apply:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

Run `check`: it waits for OK without publishing anything, then publishes a failure and expects ALARM.
