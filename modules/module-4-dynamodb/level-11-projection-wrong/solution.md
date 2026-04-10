# Solution

```bash
aws dynamodb update-table   --table-name MissionTable   --global-secondary-index-updates '[{"Delete":{"IndexName":"category-index"}}]'

aws dynamodb update-table   --table-name MissionTable   --attribute-definitions AttributeName=category,AttributeType=S   --global-secondary-index-updates '[{"Create":{"IndexName":"category-index","KeySchema":[{"AttributeName":"category","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}}]'
```
