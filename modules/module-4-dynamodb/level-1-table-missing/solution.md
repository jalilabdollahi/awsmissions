# Solution

The table was never created in this account, and the lookalike `harvest-order` (singular) has a different key. Create `harvest-orders` with farmId as partition key and orderedAt as sort key:

```bash
aws dynamodb create-table \
  --table-name harvest-orders \
  --attribute-definitions AttributeName=farmId,AttributeType=S AttributeName=orderedAt,AttributeType=N \
  --key-schema AttributeName=farmId,KeyType=HASH AttributeName=orderedAt,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```

The validator writes orders out of order for one farm and checks that a time-range query and a newest-first query return them correctly.
