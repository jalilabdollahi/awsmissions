# Solution

The hosted UI fails for two independent reasons:

1. **Callback URL.** Cognito compares `redirect_uri` with the registered URLs character for character. The client has `https://marigold.example.com/auth/callback/` (trailing slash); the app sends it without.
2. **OAuth flow.** The client only allows `implicit`, but the app asks for `response_type=code`. Cognito reports them one at a time (`Client is not allowed to use the authorization code flow`, then the redirect error), so fixing one reveals the other.

1. Reproduce and read the answer (the error is JSON):

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id> \
  --query 'UserPoolClient.[CallbackURLs,AllowedOAuthFlows,AllowedOAuthScopes]'
curl -s "$AWS_ENDPOINT_URL/cognito-idp/oauth2/authorize?client_id=<client-id>&response_type=code&scope=openid&redirect_uri=https%3A%2F%2Fmarigold.example.com%2Fauth%2Fcallback"
```

2. Update the client with the exact URLs, the code flow instead of implicit, and every other setting passed again (the call replaces settings):

```bash
aws cognito-idp update-user-pool-client --user-pool-id <pool-id> --client-id <client-id> --client-name marigold-web \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --callback-urls "https://marigold.example.com/auth/callback" "http://localhost:3000/callback" \
  --allowed-o-auth-flows code --allowed-o-auth-scopes openid email \
  --allowed-o-auth-flows-user-pool-client --supported-identity-providers COGNITO
```

3. Run `check`. It drives the real login: authorize, form sign-in as noor, the redirect with a code, and the code-for-tokens exchange; then it probes lookalike redirect URLs that must stay rejected.
