# Solution

A GSI can be added to a live table with `update-table`; DynamoDB backfills it from the existing items. The key attribute must also be declared in `--attribute-definitions`.

```bash
aws dynamodb update-table \
  --table-name cartwheel-members \
  --attribute-definitions AttributeName=email,AttributeType=S \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"email-index","KeySchema":[{"AttributeName":"email","KeyType":"HASH"}],"Projection":{"ProjectionType":"ALL"}}}]'
```

Wait for `IndexStatus` to become `ACTIVE` (`describe-table`), then query it:

```bash
aws dynamodb query --table-name cartwheel-members --index-name email-index \
  --key-condition-expression 'email = :e' \
  --expression-attribute-values '{":e":{"S":"ravi@example.org"}}'
```
