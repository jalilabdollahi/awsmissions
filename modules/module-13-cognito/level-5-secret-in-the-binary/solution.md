# Solution

`quill-web` was created with a client secret, so every call on it must carry a `SECRET_HASH` (an HMAC of the username and client ID, keyed with the secret). A phone cannot compute that without shipping the secret inside the app. The secret of an existing client cannot be removed or rotated away, so the right fix is a **second client** without one.

1. Confirm the diagnosis:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp list-user-pool-clients --user-pool-id <pool-id>
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <web-client-id> \
  --query 'UserPoolClient.ClientSecret'
```

2. Create the public client for the app:

```bash
aws cognito-idp create-user-pool-client --user-pool-id <pool-id> --client-name quill-mobile \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH
```

3. Point the mobile app at the new client ID, then run `check`. The validator signs mira in and refreshes through `quill-mobile`, and also signs her in through `quill-web` with a computed `SECRET_HASH` to prove the backend is untouched.
