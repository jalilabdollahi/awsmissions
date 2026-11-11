# Solution

`attribute_not_exists(orderId)` is a "create only" guard: it passes only when the item is absent, so on any existing order the update is refused. For a state change the guard should say "only if the order is still in the state I expect":

```bash
--condition-expression "#s = :packed" \
--expression-attribute-values '{ ... ,":packed":{"S":"PACKED"}}'
```

Edit `ship-orders.sh` accordingly (`edit`), keeping `#s` mapped to `status`, and run it. ord-1042 ships and is bumped to version 8; ord-1043 is skipped with `ConditionalCheckFailedException`, which is exactly the protection you want.

For stricter optimistic locking also compare the version you read: `#s = :packed AND version = :seen`.
