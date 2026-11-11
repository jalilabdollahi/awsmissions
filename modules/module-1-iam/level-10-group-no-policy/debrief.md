# Debrief: a group is just a bag; the policy is the permission

An IAM group has no power of its own. It is a container that hands out whatever policies are attached to it to all its members. An empty group gives its members nothing, which looks like "IAM is broken" until you realise the group was never wired up.

Two kinds of policy can be attached:

- **Managed policies** (`attach-group-policy`): standalone, reusable, versioned. Good for anything shared between groups, roles or users.
- **Inline policies** (`put-group-policy`): embedded in exactly one group. Good only for one-offs.

The security team had already written three variants with increasing power (view, agent, owner). The skill is picking the *smallest one that fits the job*, here upload and download without delete, rather than the most convenient one (`s3:*`).

**In real life**
- Prefer managed policies for shared access; change them once and every group/role using them follows.
- Keep several permission tiers per resource (read, contribute, admin) and map them to groups like `helpdesk-readers` or `helpdesk-agents`.
- `aws iam list-entities-for-policy` shows everyone who uses a managed policy before you edit it.
- Group changes are effective for existing members immediately. There is no need to re-login or rotate keys for users to pick them up.
