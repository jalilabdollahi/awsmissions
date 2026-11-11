# Solution

The secret has `username`/`password`; the dashboard asks for `user`/`pass`; the billing job needs `username`/`password`. Renaming would break the billing job, so keep every field and add the two the dashboard wants.

1. Edit `secret.json` (`edit`) so it contains all six keys:

```json
{
  "username": "wh_loader",
  "password": "Birch*Anvil-7733",
  "user": "wh_loader",
  "pass": "Birch*Anvil-7733",
  "host": "wh.cinder.internal",
  "port": "5432"
}
```

2. Store it as a new version of the existing secret:

```bash
aws secretsmanager put-secret-value --secret-id cinder/warehouse/login --secret-string file://secret.json
```

`check` reads the current version for both consumers' fields and verifies the original version remains as `AWSPREVIOUS`.
