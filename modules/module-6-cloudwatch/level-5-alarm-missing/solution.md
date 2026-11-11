# Solution

An alarm needs a metric (namespace, name, dimensions), a statistic and period, a threshold with a comparison operator, and, so that anyone hears about it, an **alarm action**.

1. Complete `alarm.json` (`edit`): a name, `Threshold: 800`, `ComparisonOperator: GreaterThanThreshold`, and the topic ARN in `AlarmActions`:

```json
{
  "AlarmName": "checkout-p99-latency-high",
  "Namespace": "Meridian/Checkout",
  "MetricName": "P99LatencyMs",
  "Statistic": "Maximum",
  "Period": 10,
  "EvaluationPeriods": 1,
  "Threshold": 800,
  "ComparisonOperator": "GreaterThanThreshold",
  "TreatMissingData": "notBreaching",
  "AlarmActions": ["arn:aws:sns:us-east-1:000000000000:meridian-oncall"]
}
```

2. Create it:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

3. Run `check`. The validator publishes 310 ms (must stay OK), then 2400 ms (must go to ALARM), then looks for the notification in the on-call queue.
