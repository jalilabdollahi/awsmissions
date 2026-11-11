# Debrief: three different ways to protect a stack

CloudFormation has three guard rails that people often mix up:

| Mechanism | What it blocks | Scope | Set with |
|---|---|---|---|
| **Termination protection** | `DeleteStack` | whole stack | `update-termination-protection` / `--enable-termination-protection` at create |
| **Stack policy** | *updates* to chosen resources (`Update:Replace`, `Update:Delete`, ...) | per resource, JSON document | `set-stack-policy` |
| **DeletionPolicy / UpdateReplacePolicy** | what happens to the real resource when it is removed or replaced | per resource, in the template | template attribute |

This mission was about the first one. It is a boolean on the stack record: while true, deletion is rejected for every caller. Nested stacks inherit the setting from their root.

**Why the cleanup job failed.** A blanket policy ("protect everything") is safe but needs an explicit unlock step for stacks that are supposed to die. The right place for that unlock is the cleanup tooling, scoped by a naming convention or a tag such as `lifecycle=preview`, never a global switch.

**Stack policies, for completeness.** A stack policy is a JSON document of Allow/Deny statements over actions like `Update:*` and resources like `LogicalResourceId/MyDatabase`. By default, once a stack has a policy, all updates are denied unless allowed. During an urgent change you can pass `--stack-policy-during-update-body` to override it for one update only. This emulator stores stack policies but does not enforce them on updates, so this mission uses the guard rail it does enforce.

**In real life**
- Combine termination protection with IAM: deny `cloudformation:UpdateTerminationProtection` for everyone except a break-glass role.
- Keep production stacks separate from previews so a clean-up script never even lists them.
