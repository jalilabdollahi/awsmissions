# Debrief: trusting the account is not the same as granting access

The two halves of a same-account AssumeRole:

| Side | Question it answers | Where it lives |
|---|---|---|
| Resource side | "Who may assume me?" | role trust policy |
| Identity side | "Which roles may this caller assume?" | the caller's identity policy (`sts:AssumeRole`) |

A trust policy that names the account root (`arn:aws:iam::<id>:root`) does not let everybody in. It says "any principal of this account that has been given permission to assume me". The permission itself still has to be granted on the identity side. If the trust policy names a specific user or role ARN, the identity side is not needed for same-account calls; across accounts both are always required.

That asymmetry is why this failed quietly: the role looked open and the user looked normal. The mistake to avoid is the quick fix `Resource: "*"`; it works for the audit role and also opens the admin role, because that trusts the account the same way.

**In real life**
- For delegated roles, list the exact role ARNs a user may assume.
- Use `Condition: {"Bool": {"aws:MultiFactorAuthPresent": "true"}}` in the trust policy for sensitive roles, and `sts:ExternalId` for third parties.
- Trust the account root for roles meant to be controlled entirely by identity policies; trust specific principals for roles meant to be locked down at the role.
- Check CloudTrail for the `AssumeRole` event; denied events show the caller ARN and role ARN.
