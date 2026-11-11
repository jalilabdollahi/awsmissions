# Solution

The alarm is correct except for one number: `"Threshold": 900`. CPU utilisation is a percentage that can never exceed 100, so a "greater than 900" alarm can never fire.

```bash
aws cloudwatch describe-alarms --alarm-names pylon-node-cpu-saturated \
  --query 'MetricAlarms[0].[Threshold,ComparisonOperator,Statistic,Period]'
```

Change `Threshold` to `90` in `alarm.json` and apply the file again. `put-metric-alarm` with an existing name replaces the alarm's settings:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

Run `check`: the validator publishes 45% (must stay OK) and 97% (must alarm).
