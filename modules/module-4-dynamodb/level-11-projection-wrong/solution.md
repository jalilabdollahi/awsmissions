# Solution

An index projection cannot be edited. Drop the index and create it again with `INCLUDE`, listing just the attributes the cards render (the table key `isbn` and the index keys `category` and `price` are always projected):

```bash
aws dynamodb update-table --table-name shelfwise-books \
  --global-secondary-index-updates '[{"Delete":{"IndexName":"category-index"}}]'

aws dynamodb update-table --table-name shelfwise-books \
  --attribute-definitions AttributeName=category,AttributeType=S AttributeName=price,AttributeType=N \
  --global-secondary-index-updates '[{"Create":{"IndexName":"category-index",
    "KeySchema":[{"AttributeName":"category","KeyType":"HASH"},{"AttributeName":"price","KeyType":"RANGE"}],
    "Projection":{"ProjectionType":"INCLUDE","NonKeyAttributes":["title","author"]}}}]'
```
