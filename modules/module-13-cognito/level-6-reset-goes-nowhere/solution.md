# Solution

Cognito only sends a recovery code to an address that is both *present* and *verified*. Omar's import left a typo (`omar@exmaple.com`) and no `email_verified` flag, so `forgot-password` refuses.

1. Read the account, and try the reset to see the exact complaint:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp admin-get-user --user-pool-id <pool-id> --username omar
aws cognito-idp forgot-password --client-id <client-id> --username omar
```

2. Fix the address **and** the flag. Only marking the typo as verified would send the code to a stranger's domain:

```bash
aws cognito-idp admin-update-user-attributes --user-pool-id <pool-id> --username omar \
  --user-attributes Name=email,Value=omar@example.com Name=email_verified,Value=true
```

3. Run `check`. The validator starts a reset for Omar, reads the mail that was sent, makes sure it went to `omar@example.com`, redeems the code and signs in with the new password.
