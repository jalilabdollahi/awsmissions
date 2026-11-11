# Debrief: Service principals and AWS principals are different animals

A trust policy's `Principal` element has several shapes:

| Principal | Who it allows |
|---|---|
| `{"Service": "lambda.amazonaws.com"}` | the Lambda service acting on your behalf (execution roles) |
| `{"Service": "ec2.amazonaws.com"}` | EC2, for instance profiles |
| `{"AWS": "arn:aws:iam::123456789012:user/alice"}` | a specific IAM user |
| `{"AWS": "arn:aws:iam::123456789012:role/ci"}` | a specific role (chaining) |
| `{"Federated": "..."}` | SAML or OIDC identity providers |

The break-glass role looked fine because cloning a working trust policy is a normal shortcut. But the clone carried the *wrong kind* of principal, so no person could ever assume it. That is exactly the kind of problem you only find during the incident, which is why break-glass access needs a regular test.

**In real life**
- Match the principal type to the caller: services for execution roles, `AWS` for people and automation, `Federated` for SSO.
- For humans, prefer federated roles (IAM Identity Center) over long-lived IAM users; for break-glass, require MFA with a `Condition` on `aws:MultiFactorAuthPresent`.
- Add alarms on `AssumeRole` calls for the break-glass role so each use is reviewed.
- Rehearse: run a monthly drill that actually assumes the role and does one harmless action.
