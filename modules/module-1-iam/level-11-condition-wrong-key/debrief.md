# Debrief: a misspelled condition key silently matches nothing

IAM `Condition` blocks compare **context keys** the request carries against the values you give. There are three families:

- **Global keys** (`aws:` prefix): `aws:RequestedRegion`, `aws:SourceIp`, `aws:PrincipalTag/...`, `aws:SecureTransport`, `aws:MultiFactorAuthPresent`...
- **Service keys**: `s3:prefix`, `sqs:...`, `ec2:InstanceType`...
- **Tag keys**: `aws:RequestTag/...`, `aws:ResourceTag/...`.

A key that does not exist is simply missing from the request context, so the condition evaluates to false and an `Allow` does nothing. IAM does not report this at save time, so a typo behaves like "this policy is broken".

**In real life**
- Copy keys from the *Service Authorization Reference* (the "condition keys" tables) rather than guessing.
- The usual regional guardrail is the other way round: an `Allow` for what the team needs plus a separate `Deny` with `StringNotEquals: aws:RequestedRegion`, because global services (IAM, CloudFront, Route 53) are called through us-east-1 and need an exception list.
- If a condition-based `Deny` has a typo in its key, it silently stops protecting you. Test both the allowed and the forbidden request, as the checker does here.
- Use IAM Access Analyzer's policy validation: it warns about unknown condition keys.
