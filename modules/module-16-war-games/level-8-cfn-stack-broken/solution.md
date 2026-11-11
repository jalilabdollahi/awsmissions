# Solution

All four fixes go into `orders-stack.yaml`, followed by one in-place update. Do **not** delete the stack first: the table has no `DeletionPolicy`, so a delete would erase finance's data.

1. **Export collision.** `Export.Name: cobalt-orders-queue-arn` belongs to `cobalt-core`. Rename the new export (for example `cobalt-ledger-table-arn`).
2. **Protect the data.** Add `DeletionPolicy: Retain` to `LedgerTable`.
3. **Function environment.** `TABLE_NAME: cobalt-ledgers` should be `cobalt-ledger`.
4. **Function role.** Add a `Policies` entry to `LedgerFnRole` granting `dynamodb:Scan` on `!GetAtt LedgerTable.Arn`.

```bash
aws cloudformation update-stack --stack-name cobalt-orders \
  --template-body file://orders-stack.yaml --capabilities CAPABILITY_NAMED_IAM
```

`check` confirms `cobalt-core` and its export are untouched, entry `E-1` is still in the table, the stack is `*_COMPLETE`, the template carries a Retain policy, and the function can invoke successfully.
