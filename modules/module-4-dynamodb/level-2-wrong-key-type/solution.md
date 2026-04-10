# Solution

```bash
aws dynamodb delete-table --table-name MissionTable

aws dynamodb create-table   --table-name MissionTable   --attribute-definitions AttributeName=userId,AttributeType=S   --key-schema AttributeName=userId,KeyType=HASH   --billing-mode PAY_PER_REQUEST
```
