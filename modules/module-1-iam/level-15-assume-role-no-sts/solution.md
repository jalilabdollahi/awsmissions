# Solution

Within one account, assuming a role needs two yeses: the role's trust policy and the caller's identity policy. Here the trust policy trusts the account root (so it delegates the decision to identity policies), but `cobalt-auditor` has no `sts:AssumeRole` permission at all.

1. Check the user's policy and the role's trust:

```bash
aws iam get-user-policy --user-name cobalt-auditor --policy-name auditor-base
aws iam get-role --role-name cobalt-audit-readonly --query Role.AssumeRolePolicyDocument
```

2. Add a statement to `policy.json` (`edit`) that allows `sts:AssumeRole` on the audit role only:

```json
{
  "Sid": "SwitchToAuditRole",
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::000000000000:role/cobalt-audit-readonly"
}
```

3. Apply it:

```bash
aws iam put-user-policy --user-name cobalt-auditor --policy-name auditor-base --policy-document file://policy.json
```

`Resource: "*"` would also let the auditor assume `cobalt-finance-admin`, which trusts the account in the same way. `check` verifies that it is still refused.
