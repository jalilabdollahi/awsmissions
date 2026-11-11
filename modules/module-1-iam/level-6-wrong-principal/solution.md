# Solution

The role's trust policy names `ledger-batch` in account `210987654321`, the account Orbit Ledger left behind. STS checks the caller's real ARN (`arn:aws:iam::000000000000:user/ledger-batch`) against the trust policy; they differ in the account ID, so it refuses.

1. Look at the trust policy and at your own account:

```bash
aws iam get-role --role-name ledger-nightly --query Role.AssumeRolePolicyDocument
aws sts get-caller-identity
```

2. In `trust-policy.json` (`edit`) change the Principal to `arn:aws:iam::000000000000:user/ledger-batch`.
3. Replace the trust policy:

```bash
aws iam update-assume-role-policy --role-name ledger-nightly --policy-document file://trust-policy.json
```

Trusting `arn:aws:iam::000000000000:root` would also make it work, but then every user in the account who may call `sts:AssumeRole` could take the role. `check` tests that `temp-auditor` is still locked out.
