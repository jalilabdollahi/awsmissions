# Debrief: why third-party roles need an external ID

When a vendor serves many customers from one AWS account, you give it a role to assume. The danger is the **confused deputy**: another customer of the same vendor could tell the vendor "use *this* role ARN", and the vendor's trusted account would dutifully assume your role on their behalf.

The fix is a secret both sides know. The role's trust policy requires `sts:ExternalId` to equal a value that only your relationship with the vendor uses. The vendor's service must pass it on every `AssumeRole` call (`--external-id`). Another customer cannot guess your value, so the vendor cannot be tricked into acting for them.

Properties to remember:

- The external ID is **not a password**; it is an identifier that the vendor generates per customer and that you do not need to keep as secret as a key. What matters is that it is unique and not chosen by the attacker.
- Comparison is an exact string match (`StringEquals`), so a swapped digit blocks everything. Copy and paste, never retype.
- The condition lives in the **trust policy** (resource side). It cannot be added on the caller's identity policy.

**In real life**
- Insist on a vendor-generated, per-customer external ID (CloudFormation templates from vendors often have it as a parameter).
- Never "fix" an access issue by deleting the `Condition`; it silently removes the protection.
- CloudTrail's `AssumeRole` events show `requestParameters.externalId` when something fails, which helps debugging.
