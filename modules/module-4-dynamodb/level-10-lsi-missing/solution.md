# Solution

```bash
aws dynamodb delete-table --table-name MissionTable

aws dynamodb create-table   --table-name MissionTable   --attribute-definitions     AttributeName=id,AttributeType=S     AttributeName=createdAt,AttributeType=S     AttributeName=status,AttributeType=S   --key-schema     AttributeName=id,KeyType=HASH     AttributeName=createdAt,KeyType=RANGE   --local-secondary-indexes '[{"IndexName":"status-index","KeySchema":[{"AttributeName":"id","KeyType":"HASH"},{"AttributeName":"status","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}]'   --billing-mode PAY_PER_REQUEST
```
