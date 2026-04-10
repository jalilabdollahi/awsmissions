# Solution

```bash
aws dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=id,AttributeType=S   --key-schema AttributeName=id,KeyType=HASH   --billing-mode PAY_PER_REQUEST
```
