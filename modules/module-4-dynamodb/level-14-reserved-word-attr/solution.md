# Solution

```bash
# Edit the local file first
$EDITOR query.json
# This edited file applies to: TableName MissionTable, KeyConditionExpression #s = :val, ExpressionAttributeNames #s=status

# Then run the query with an expression attribute name
aws dynamodb query --cli-input-json file://query.json
```
