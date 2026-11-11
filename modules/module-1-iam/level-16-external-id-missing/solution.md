# Solution

The trust policy requires `sts:ExternalId` to equal `mw-5d1f-prod-8814`, but the vendor's agent sends `mw-5d1f-prod-8841` (two digits swapped when someone typed it in). STS compares the strings exactly, so every call is rejected.

1. Read the trust policy:

```bash
aws iam get-role --role-name metricwave-reader --query Role.AssumeRolePolicyDocument
```

2. Set the condition value to the ID from the onboarding sheet in `trust-policy.json` (`edit`):

```json
"Condition": { "StringEquals": { "sts:ExternalId": "mw-5d1f-prod-8841" } }
```

3. Update the role's trust policy:

```bash
aws iam update-assume-role-policy --role-name metricwave-reader --policy-document file://trust-policy.json
```

Deleting the Condition would also make the vendor's call succeed, but it would remove the confused-deputy protection. `check` tests the right ID, no ID and a wrong ID.
