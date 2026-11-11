# Solution

During the "tidy-up" `alias/orders-prod` was moved onto the staging key. The production key still exists, enabled, but nothing points at it.

1. See the aliases and identify the production key (description and tags):

```bash
aws kms list-aliases --query 'Aliases[?contains(AliasName, `orders`)]'
aws kms list-keys
aws kms describe-key --key-id <KeyId>
aws kms list-resource-tags --key-id <KeyId>
```

2. Repoint the existing alias:

```bash
aws kms update-alias --alias-name alias/orders-prod --target-key-id <production KeyId>
```

3. `check` decrypts the old production record to learn which key is the real production key, then verifies the alias targets it, that `alias/orders-staging` still targets a different key, and that a fresh encryption through `alias/orders-prod` uses the production key.
