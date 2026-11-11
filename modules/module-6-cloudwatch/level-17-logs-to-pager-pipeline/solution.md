# Solution

Trace one ERROR line through the chain and ask at each link: what does it look like here?

1. **Log line to filter.** The filter pattern is `"error"`; patterns are case-sensitive, and the API writes `ERROR`. Nothing is ever counted.
2. **Filter to metric to alarm.** The filter publishes to namespace `Talon/Orders`, but the alarm watches `Talon/Order`. A metric is identified by namespace, name and dimensions; a one-letter difference is a different metric that never receives data.
3. **Alarm to pager.** The action and the topic are fine.

```bash
aws logs describe-metric-filters --log-group-name /talon/orders-api
aws cloudwatch describe-alarms --alarm-names talon-order-errors-high
aws logs test-metric-filter --filter-pattern '"error"' --log-event-messages "ERROR order 1 failed"
```

Fix `filterPattern` to `"\"ERROR\""` in `filter.json` and `Namespace` to `Talon/Orders` in `alarm.json`, then re-apply both:

```bash
aws logs put-metric-filter --cli-input-json file://filter.json
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

Run `check`: it logs 6 INFO and 5 ERROR lines and waits for the alarm and the page.
