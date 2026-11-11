# Debrief: PT-2026-014, the skeleton-key deploy role

## The paths
| # | Permission(s) | What an attacker does |
|---|---|---|
| 1 | `iam:CreateRole` + `iam:AttachRolePolicy` on `*` | Create a role, attach `AdministratorAccess`, assume it |
| 2 | `iam:PassRole` on `*` + `lambda:CreateFunction` | Create a function that runs as `qf-platform-admin-role`, then invoke it to act as admin |
| 3 | `iam:CreateAccessKey` on `*` | Create credentials for the admin user |
| 4 | `iam:PutRolePolicy` on `*` | Add `Action: *` to its own role |

## Timeline
- 2024: pipeline set up with "whatever it asks for".
- 2026-10: red team engagement starts with the CI user's keys, which live in the CI vendor's secret store.
- 2026-11: report lands. All four paths worked on the first try; the entire chain took under ten minutes.

## Why these are classic
Every one of these permissions looks like normal automation, but each can grant permissions the caller never had. IAM does not stop you from giving someone else (or yourself) access, unless the policy restricts that action. That is why the safe unit of design is "what can this identity create or change, and what can the new thing do?" not only "what can this identity read?".

## Lessons
- Treat `iam:*` write actions, `iam:PassRole`, `sts:AssumeRole` and key-creation as admin-equivalent. Scope their resources tightly, or avoid them.
- Scope `iam:PassRole` to specific role ARNs, and add `iam:PassedToService` conditions where possible.
- Use permission boundaries when automation genuinely must create roles: the new role can never exceed the boundary.
- Review policies with an attacker's mindset: IAM Access Analyzer, `simulate-principal-policy`, and periodic red-team exercises.
- Fix by narrowing, not by turning the pipeline off; a broken release process creates its own pressure to bypass controls.
