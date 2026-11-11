# Solution

With only a partition key, the primary key of an item is just `ticketId`, so every new event overwrites the previous one. Add `eventAt` as the sort key. The key schema is immutable, so recreate the table (the surviving rows are only the last event per ticket and may be dropped):

```bash
aws dynamodb delete-table --table-name fixline-ticket-events
aws dynamodb create-table \
  --table-name fixline-ticket-events \
  --attribute-definitions AttributeName=ticketId,AttributeType=S AttributeName=eventAt,AttributeType=S \
  --key-schema AttributeName=ticketId,KeyType=HASH AttributeName=eventAt,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST
```
