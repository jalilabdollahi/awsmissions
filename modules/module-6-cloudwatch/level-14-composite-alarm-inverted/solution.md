# Solution

A composite alarm evaluates a boolean expression over the *states* of other alarms. The deployed rule wraps the condition in `NOT (...)`, so it is true exactly when neither child is in ALARM, which is whenever the service is healthy.

```bash
aws cloudwatch describe-alarms --alarm-types CompositeAlarm --alarm-names strata-api-unhealthy \
  --query 'CompositeAlarms[0].[AlarmRule,StateValue,AlarmActions]'
```

Remove the `NOT` and keep the `OR`, so that either failing child raises the composite:

```
ALARM("strata-api-errors") OR ALARM("strata-api-latency")
```

`put-composite-alarm` replaces the whole definition, so pass the action again:

```bash
aws cloudwatch put-composite-alarm --alarm-name strata-api-unhealthy \
  --alarm-rule "$(cat alarm-rule.txt)" \
  --alarm-actions arn:aws:sns:us-east-1:000000000000:strata-oncall
```

Run `check`: it waits for the composite to be calm, breaks only the latency metric, and expects ALARM.
