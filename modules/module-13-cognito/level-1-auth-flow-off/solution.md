# Solution

The `brewline-app` client only lists `ALLOW_USER_SRP_AUTH` and `ALLOW_REFRESH_TOKEN_AUTH`. A client accepts exactly the flows in its `ExplicitAuthFlows` list, and `USER_PASSWORD_AUTH` is not in it.

1. Find the pool and the client:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp list-user-pool-clients --user-pool-id <pool-id>
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id> \
  --query 'UserPoolClient.ExplicitAuthFlows'
```

2. Write the **complete** list of flows back, with the new one added. `update-user-pool-client` replaces the list, it does not append:

```bash
aws cognito-idp update-user-pool-client \
  --user-pool-id <pool-id> --client-id <client-id> --client-name brewline-app \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_USER_SRP_AUTH ALLOW_REFRESH_TOKEN_AUTH
```

3. Run `check`. The validator signs in as nora, refreshes the session with the refresh token, and confirms SRP is still enabled and that no admin flow was switched on.
