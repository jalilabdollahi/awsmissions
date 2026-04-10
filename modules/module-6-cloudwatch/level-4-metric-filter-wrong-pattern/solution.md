# Solution

```bash
# Edit the local mission artifact first
$EDITOR filter.json
# This edited file applies to: --log-group-name /aws/lambda/mission-function

# Then apply the fix
aws logs put-metric-filter --filter-name error-filter --log-group-name /aws/lambda/mission-function --filter-pattern "ERROR:" --metric-transformations metricName=ErrorCount,metricNamespace=Mission,metricValue=1
```
