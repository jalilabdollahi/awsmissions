# Debrief: FM-2026-Q3, the missing bridge

## Root causes
| Hop | Half | Fault |
|---|---|---|
| auditor to bridge | caller's identity policy | Resource ARN misspelt (`brigde`) |
| auditor to bridge | bridge's trust policy | ExternalId from last year's engagement |
| bridge to reader | reader's trust policy | principal still the bridge's old name `...-v1` |
| reader to data | reader's identity policy | bucket ARN with a stray `s`, so the Allow matches nothing |

## Timeline
- Last week: Ferro rebuilds the chain from an old design after renaming the bridge role.
- Day 1 of fieldwork: auditor gets `AccessDenied` on hop 1 and the thread assumes "the ExternalId is wrong".
- Fixing the ExternalId alone just reveals the next AccessDenied. Four people each fix "their" hop.

## How AWS evaluates AssumeRole
Same-account `sts:AssumeRole` needs BOTH an allow on the caller's side (identity policy on `sts:AssumeRole` for the target role ARN) and a matching trust policy on the role. In a true cross-account setup each side lives in a different account, which is why these faults are so common: two teams, two policies, one string that must match exactly. Role chaining (a role session assuming another role) re-applies the same rules to the session's role, and caps session duration to one hour in real AWS.

ExternalId is not a secret; it is a unique value that stops a third party from tricking a service of yours into assuming a customer's role (the confused-deputy problem). Removing it to "make it work" removes the protection, which is why the check refuses a missing or arbitrary ExternalId.

## Lessons
- Test AssumeRole hop by hop from the caller's side; the error message rarely says which half failed.
- Treat role renames as breaking changes: grep every trust policy for the old ARN.
- Never use `Resource: "*"` for `sts:AssumeRole`; one over-trusting break-glass role and the auditor is an admin.
- A policy Allow for a resource that does not exist is silently useless. IAM will not warn you about typos.
