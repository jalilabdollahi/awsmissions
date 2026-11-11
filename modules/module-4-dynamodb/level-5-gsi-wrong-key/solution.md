# Solution

An index's key schema cannot be modified, but an index can be dropped and re-created online without touching the table's items. Delete `sku-index`, wait until it is gone, then create it again keyed on `sku` (partition) and `qty` (sort).

```bash
aws dynamodb update-table --table-name stockroom-bins \
  --global-secondary-index-updates '[{"Delete":{"IndexName":"sku-index"}}]'

aws dynamodb update-table --table-name stockroom-bins \
  --attribute-definitions AttributeName=sku,AttributeType=S AttributeName=qty,AttributeType=N \
  --global-secondary-index-updates \
  '[{"Create":{"IndexName":"sku-index","KeySchema":[{"AttributeName":"sku","KeyType":"HASH"},{"AttributeName":"qty","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}}]'
```

(Wait for the delete to finish before creating; the name cannot be reused while the old index still exists.)
