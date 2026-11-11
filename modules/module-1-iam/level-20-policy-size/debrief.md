# Debrief: IAM policies have size limits

IAM enforces hard limits on policy size, and they depend on where the policy lives:

| Where | Limit (characters, excluding whitespace) |
|---|---|
| Inline policy on a **user** | 2,048 total across all of that user's inline policies |
| Inline policy on a **group** | 5,120 total |
| Inline policy on a **role** | 10,240 total |
| **Managed** policy | 6,144 per policy (attach up to 10 per identity by default) |
| Role trust policy | 2,048 by default (can be raised) |

Policy generators, and copy-pasting one statement per resource, hit these limits easily, and the only symptom is a `LimitExceeded` error at the moment you try to save.

The ways out, in order of preference:

1. **Consolidate.** Replace long lists with a pattern (`fleet-*-telemetry`), use `NotResource` carefully, or group actions with wildcards (`s3:Get*`). Make sure the pattern cannot match anything you did not mean to include.
2. **Use a managed policy.** The limit is larger and it can be reused by several users, groups and roles.
3. **Change the model.** Many resources that follow a naming scheme can be matched with a condition (for example tags: `aws:ResourceTag/team` equals `aws:PrincipalTag/team`) so the policy does not grow with every bucket.

**In real life**
- Prefer one managed policy per job function over one giant inline policy per person.
- Use attribute-based access control (ABAC) instead of listing resources when you have dozens of them.
- Watch the other side of the story: very short policies with broad wildcards are easy to write and easy to over-grant. Test the "must not" cases, as the checker here does with the payroll bucket.
