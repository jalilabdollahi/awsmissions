# Debrief: an explicit Deny always wins

AWS evaluates a request in a fixed order:

1. **Explicit Deny** in any applicable policy → the request is denied. Nothing can override it.
2. **Explicit Allow** in an identity or resource policy (and within any boundary/SCP) → allowed.
3. Otherwise → **implicit deny**.

That is why "just add another Allow" never fixes a Deny. The only real fixes are to remove the Deny or narrow it so it no longer matches the request.

**Why it bit PixelForge:** a cleanup script turned "statements we don't recognise" into Deny statements. The policy still *looked* right at a glance: correct action, correct bucket, correct prefix.

**In real life**
- `aws iam simulate-principal-policy` tells you exactly which statement decided an action. Reach for it before you edit anything.
- In CloudTrail, an `AccessDenied` with `"explicit deny"` in the error message points at a Deny statement, not a missing Allow.
- Use Deny on purpose for guardrails (for example, deny `s3:DeleteBucket` everywhere), and keep it in clearly named statements so nobody "fixes" it by accident.
