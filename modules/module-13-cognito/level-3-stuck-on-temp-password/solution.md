# Solution

Users created by an administrator start in the status `FORCE_CHANGE_PASSWORD`. Until the temporary password is replaced, a sign-in does not return tokens; it returns the challenge `NEW_PASSWORD_REQUIRED`, which Ines's portal cannot answer.

1. See the state:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp admin-get-user --user-pool-id <pool-id> --username ines --query UserStatus
```

2. As the administrator, set the permanent password. The `--permanent` flag is what moves the account to `CONFIRMED`:

```bash
aws cognito-idp admin-set-user-password --user-pool-id <pool-id> --username ines \
  --password 'Harbor-Crane-81x' --permanent
```

(The other route is to answer the challenge as Ines with `initiate-auth` followed by `respond-to-auth-challenge --challenge-name NEW_PASSWORD_REQUIRED`.)

3. Run `check`. The validator signs in as Ines and expects tokens, signs in as Tomas to make sure he is untouched, and reads Ines's status.
