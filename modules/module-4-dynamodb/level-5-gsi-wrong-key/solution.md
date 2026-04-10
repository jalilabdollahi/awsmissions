# Solution

```bash
aws dynamodb update-table   --table-name MissionTable   --global-secondary-index-updates '[{"Delete":{"IndexName":"email-index"}}]'

aws dynamodb update-table   --table-name MissionTable   --attribute-definitions AttributeName=email,AttributeType=S   --global-secondary-index-updates '[{"Create":{"IndexName":"email-index","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}}]'
```
