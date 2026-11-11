# Solution

The key attribute `recipientId` was declared with type `N`, so DynamoDB rejects every string value. Key types cannot be altered, so the table has to be replaced. It is empty, so nothing is lost. Deletion protection blocks `delete-table` until you turn it off.

```bash
aws dynamodb update-table --table-name postbox-prefs --no-deletion-protection-enabled
aws dynamodb delete-table --table-name postbox-prefs
aws dynamodb create-table \
  --table-name postbox-prefs \
  --attribute-definitions AttributeName=recipientId,AttributeType=S \
  --key-schema AttributeName=recipientId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --deletion-protection-enabled
```

Re-enabling deletion protection on the new table is optional, and a good habit.
