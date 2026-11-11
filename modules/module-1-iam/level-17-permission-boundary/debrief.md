# Debrief: boundaries are ceilings, not grants

A **permissions boundary** is a managed policy attached to a user or role as a maximum. It never grants anything by itself; it only caps what the identity policies can grant:

effective permissions = identity policies ∩ permissions boundary

(then also minus any explicit Deny and SCP).

That is why staring at the identity policy was useless: it said `s3:*` on `*`, and the boundary silently cut most of it away. There is no "denied by boundary" in the error message of most services, only `AccessDenied`.

**Why use them:** to let teams create their own roles and users without being able to escalate. A developer may create roles only if the new role carries the boundary, so those roles can never exceed it.

**In real life**
- When an action with a matching Allow is denied, check boundaries and SCPs next. `aws iam get-user` / `get-role` show the `PermissionsBoundary`; `simulate-principal-policy` accounts for it.
- Boundaries do not apply to resource-based policy grants that name the principal directly (for example an S3 bucket policy naming the user ARN in the same account), a common surprise.
- Edit the boundary, do not strip it: in this mission removing the boundary would unblock the upload, but also hand the intern the whole `s3:*` identity policy.
- A managed policy keeps at most five versions; the change takes effect for everyone using it right away.
