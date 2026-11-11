# Solution

`update-user-pool-client` is a **replace**, not a patch. Every setting you leave out goes back to its default. Yesterday's call listed the callback URLs and the OAuth settings, so those survived. The auth flows were not listed (now empty), and the token lifetimes went back to the defaults (60 minutes for access and ID tokens, 30 days for the refresh token).

1. Look at the client as it is now:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id>
```

2. Write the complete configuration in one call, flows and lifetimes included:

```bash
aws cognito-idp update-user-pool-client --user-pool-id <pool-id> --client-id <client-id> \
  --client-name skylark-spa \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --access-token-validity 30 --id-token-validity 30 --refresh-token-validity 14 \
  --token-validity-units AccessToken=minutes,IdToken=minutes,RefreshToken=days \
  --callback-urls https://app.example.com/auth/callback https://preview.example.com/cb \
  --logout-urls https://app.example.com/signed-out \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email profile \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO
```

3. Run `check`. It signs yuki in, measures the real lifetime of both tokens, refreshes, and probes the hosted-UI authorize endpoint for both callback URLs and for an unregistered one.
