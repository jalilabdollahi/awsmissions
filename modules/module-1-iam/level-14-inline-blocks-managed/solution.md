# Solution

An explicit Deny overrides every Allow, including the one from `AmazonS3FullAccess`. The user carries three inline policies; one of them is a leftover from a 2023 release freeze that denies `PutObject` and `DeleteObject` on every resource.

1. Look at everything attached to the user:

```bash
aws iam list-attached-user-policies --user-name forge-deployer
aws iam list-user-policies --user-name forge-deployer
aws iam get-user-policy --user-name forge-deployer --policy-name release-freeze-2023
aws iam get-user-policy --user-name forge-deployer --policy-name ledger-write-protect
```

2. `release-freeze-2023` is stale and covers `Resource: "*"`. `ledger-write-protect` is deliberate and scoped to `forge-ledger-prod`. Delete only the first:

```bash
aws iam delete-user-policy --user-name forge-deployer --policy-name release-freeze-2023
```

Deleting every inline policy would unblock the artifacts bucket too, but it would also remove the ledger protection. `check` tests both.
