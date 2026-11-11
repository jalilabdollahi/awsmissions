# Solution

An alarm looks at the metric in windows of `Period` seconds. With a 300-second period and a single evaluation period, a burst is judged against a five-minute aggregate, and the alarm can only react once that window has been assembled. The statistic, the threshold and the comparison are all right; the window is too coarse.

```bash
aws cloudwatch describe-alarms --alarm-names brightside-bounce-spike \
  --query 'MetricAlarms[0].[Period,EvaluationPeriods,Statistic,Threshold]'
```

Lower `Period` in `alarm.json` to `60` (the shortest period for a standard-resolution metric), keep `EvaluationPeriods` at 1, and apply it:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

Run `check`: it confirms the alarm now needs at most one minute of data (Period x EvaluationPeriods <= 60s), then sends a burst of 300 bounces and waits for the alarm to reach ALARM.
