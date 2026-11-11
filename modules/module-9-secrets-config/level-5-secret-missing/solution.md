# Solution

The secret was not lost, only scheduled for deletion with a 14 day recovery window. While a deletion is pending, `GetSecretValue` fails with `InvalidRequestException: You can't perform this operation on the secret because it was marked for deletion`.

```bash
aws secretsmanager describe-secret --secret-id wyvern/matchmaker/db-credentials   # DeletedDate is set
aws secretsmanager restore-secret --secret-id wyvern/matchmaker/db-credentials
```

`check` confirms the `DeletedDate` is gone and that the secret still holds the original username, password and host.
