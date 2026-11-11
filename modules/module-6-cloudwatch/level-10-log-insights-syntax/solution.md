# Solution

The widget query has two small mistakes, and either one gives an empty table:

1. It reads `SOURCE '/rivergate/payment'` (singular). The group is `/rivergate/payments`.
2. It filters on `Level`. Logs Insights discovers the JSON fields as they are written, and field names are case-sensitive: the field is `level`.

Compare with the data by running the query yourself:

```bash
aws logs start-query --log-group-name /rivergate/payments \
  --start-time $(( $(date +%s) - 3600 )) --end-time $(( $(date +%s) + 60 )) \
  --query-string 'fields @timestamp, @message | filter level = "ERROR"'
aws logs get-query-results --query-id <queryId>
```

Fix the `query` in `dashboard.json` and publish the dashboard again:

```bash
aws cloudwatch put-dashboard --dashboard-name rivergate-payments --dashboard-body file://dashboard.json
```

Run `check`: the validator takes the widget's query from the live dashboard, runs it, and expects exactly the three ERROR entries.
