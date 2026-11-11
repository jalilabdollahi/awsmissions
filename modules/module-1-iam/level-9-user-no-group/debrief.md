# Debrief: permissions flow through groups

A new IAM user starts with **zero** permissions: every API call is an implicit deny. Groups are the standard way to hand out permissions to people. A user's effective permissions are the union of:

- policies attached directly to the user,
- inline and managed policies of **every group** they belong to,
- minus anything an explicit Deny, boundary or SCP takes away.

Priya was missing the membership, not a policy. The tempting shortcut here is to put her into the admin group "to unblock her", which silently turns a data analyst into an account administrator.

**In real life**
- Name groups after job functions (analysts, billing, platform), not after individuals, and keep user-level policies at zero. Offboarding then becomes "remove from group".
- Audit group membership regularly; `aws iam get-group` and the credential report show who is where.
- A user can belong to up to 10 groups. If you need more, you are probably modelling permissions in groups where roles or attribute-based access would be cleaner.
- Today most teams use IAM Identity Center (SSO) and permission sets instead of IAM users and groups, but the evaluation logic underneath is the same.
