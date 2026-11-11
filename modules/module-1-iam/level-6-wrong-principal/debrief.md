# Debrief: AssumeRole needs a yes from both sides

To assume a role in the same account, **both** of these must allow it:

1. the caller's **identity policy** (`sts:AssumeRole` on the role's ARN), and
2. the role's **trust policy** (the caller is a trusted `Principal`).

`ledger-batch` passed the first check. The second one failed because the trust policy referenced a principal from a different account: after the consolidation the ARN still contained the old account ID. A trust policy never errors on a principal that does not exist for the caller, it just never matches.

**In real life**
- Principal ARNs are exact: account ID, resource type (`user`, `role`), path and name must all match.
- `"Principal": {"AWS": "arn:aws:iam::<account>:root"}` means "any principal in that account that is itself allowed to assume the role". It is a common shortcut and a common over-grant. Prefer the specific user or role.
- If you delete and recreate a trusted user or role, AWS replaces the stored principal with an opaque ID (`AIDA...`) when the original is gone, and the trust policy shows that ID instead of an ARN.
- The `CloudTrail` event for the failed call, `AssumeRole`, tells you which ARN was the caller.
