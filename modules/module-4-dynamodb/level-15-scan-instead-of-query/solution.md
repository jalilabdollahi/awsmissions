# Solution

```bash
# Edit the local request file so it uses Query inputs
$EDITOR request.json
# This edited file applies to: TableName MissionTable, KeyConditionExpression userId = :u, ExpressionAttributeValues ...

# Then query by key instead of scanning the whole table
aws dynamodb query --cli-input-json file://request.json
```
