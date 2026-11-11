# Debrief: trust policy versus permissions policy

An IAM role answers two separate questions, and CloudFormation models them with two separate properties:

| Question | Where it lives | Required in `AWS::IAM::Role`? |
|---|---|---|
| Who may become this role? | `AssumeRolePolicyDocument` (trust policy) | yes |
| What may the role do? | `Policies` / `ManagedPolicyArns` | no |

The role also needs the *caller* to be allowed to call `sts:AssumeRole` on it. Both sides must say yes: the trust policy on the role, and an identity policy on the caller (unless they are in the same account and the trust policy names the caller's ARN directly).

**Why nothing failed at deploy time.** Real CloudFormation would refuse a template that omits a required property. Tolerant tooling (including this emulator) may build the role with an empty trust policy instead. An empty trust policy is valid IAM, it just trusts nobody, so the stack looks fine and the failure only shows up at runtime as `AccessDenied` on `AssumeRole`.

**In real life**
- Name the narrowest principal: a specific role or user ARN. `Principal: "*"` in a trust policy opens the role to every principal in the account that is allowed to call STS, and to anyone at all if you also drop conditions.
- Add `sts:ExternalId` or `aws:PrincipalOrgID` conditions for cross-account roles.
- `aws iam simulate-principal-policy` does not evaluate trust policies; testing the real `assume-role` call is the reliable check.
