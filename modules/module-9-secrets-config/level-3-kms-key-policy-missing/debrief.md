# Debrief: KMS key policies are the gatekeeper

For most AWS services, an IAM identity policy *or* a resource policy is enough to allow an action within an account. KMS is stricter:

> A principal can use a KMS key only if the **key policy** allows it, either by naming the principal directly, or by allowing the account root, which delegates control to IAM policies.

The AWS-created default policy has exactly one statement, `Principal: arn:aws:iam::<account>:root`, `Action: kms:*`, which turns the key into a normal IAM-controlled resource. A custom policy that omits it makes the key private to the principals it lists, and even account administrators cannot use it until the policy is fixed (the account root can still repair it).

**Two ways to grant the role access**
1. *Direct*: a statement for the role's ARN with only the actions it needs (what this mission asks for). The role needs no IAM permissions at all for that key.
2. *Delegated*: restore the root statement and manage permissions in IAM policies. Easier to audit across many keys; needs both sides to agree.

**Separation of duties.** The key-administrator statement lists management actions but not `Encrypt`/`Decrypt`, so administrators cannot read the data they protect. Keep users, admins and services in separate statements.

**Traps**
- Putting `"Principal": "*"` without conditions makes the key usable by anyone who can reach KMS in the account.
- `kms:*` for an application role lets it schedule deletion of its own key.
- For cross-account use, the key policy must allow the other account *and* that account must grant its principals access in IAM.

**Note about this emulator.** It enforces IAM identity policies for KMS calls but does not evaluate key policies, so the check reads the stored policy instead of relying on an AccessDenied. In real AWS the denial would appear as `AccessDeniedException ... because no resource-based policy allows the kms:Decrypt action`.
