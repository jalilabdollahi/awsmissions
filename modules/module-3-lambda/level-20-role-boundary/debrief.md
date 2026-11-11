# Debrief: boundaries only ever subtract

IAM evaluates a role session like this: a request is allowed only if
- an identity policy allows it, **and**
- the permissions boundary (if any) allows it, **and**
- nothing (policies, SCPs, session policies) explicitly denies it.

A **permissions boundary** is a managed policy attached to a role or user as a *ceiling*. It never grants anything by itself; it only limits what the identity policies can grant. That has two consequences you saw in this mission:

1. Reviewing the role's policy alone proves nothing. `ssm:GetParameter` is allowed there, yet the effective result is "denied" because the ceiling lacks it. When an action is allowed in the policy and still `AccessDenied`, suspect a boundary, an SCP, a session policy or a resource policy.
2. The same ceiling is what makes the stray `dynamodb:*` harmless. Removing the boundary to "fix" SSM would silently activate that over-grant, so the checker asks the function itself whether DynamoDB is still blocked.

**Why self-service portals use boundaries:** they let teams create roles themselves while guaranteeing nobody can exceed what the platform team pre-approved, including privilege escalation through IAM.

**Editing a managed policy.** You cannot edit a policy in place: you create a new *version* and make it the default (max 5 versions; delete old ones to make room). Every identity using the policy picks up the new default immediately, so changing a shared boundary affects *all* roles that use it. Keep the change as narrow as this one (single action, single parameter path).

**In real life**
- `aws iam simulate-principal-policy` reports boundary effects as `PermissionsBoundaryDecisionDetail`.
- CloudTrail `errorMessage` text distinguishes "no identity-based policy allows" from "with an explicit deny"; boundaries show up as the former.
- For SecureString parameters you also need `kms:Decrypt` on the key unless the default key is used.
