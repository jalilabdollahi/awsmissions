# Solution

The pool demands 24 characters **and** a symbol. The agreed rule needs 10 characters and no symbol.

1. Read the current policy:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp describe-user-pool --user-pool-id <pool-id> --query 'UserPool.Policies.PasswordPolicy'
```

2. Replace it with the agreed rule:

```bash
aws cognito-idp update-user-pool --user-pool-id <pool-id> \
  --policies 'PasswordPolicy={MinimumLength=10,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}'
```

3. Run `check`. The validator signs up a reader with `Tidewater42Books` and then tries four weak passwords (too short, no digit, no upper-case, no lower-case) to make sure the policy still rejects them.
