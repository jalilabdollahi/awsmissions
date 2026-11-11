# Solution

The threshold (10) and the metric are right, but the operator is `GreaterThanThreshold`. For a *free space* metric the bad direction is **down**, so the alarm fires exactly when everything is fine and stays quiet when the disk is full.

```bash
aws cloudwatch describe-alarms --alarm-names nimbus-data-volume-low-space \
  --query 'MetricAlarms[0].[Threshold,ComparisonOperator,StateValue,StateReason]'
```

Change `ComparisonOperator` in `alarm.json` to `LessThanThreshold` and re-apply it:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

Run `check`: it reports 55 GB free (must not alarm) and then 4 GB free (must alarm).
