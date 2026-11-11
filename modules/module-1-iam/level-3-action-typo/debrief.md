# Debrief: IAM does not spell-check

When you save a policy, IAM validates the JSON grammar, not whether `s3:GetObjcet` is a real action. The statement is stored happily and simply never matches anything. The failure only shows up at runtime, as a plain `AccessDenied` with no hint that a typo exists.

**Why it is easy to miss:** the typo sits in a perfectly valid-looking string, and reviewers read for meaning, not spelling.

**In real life**
- Run policies through IAM Access Analyzer's policy validation (or `aws accessanalyzer validate-policy`): it flags unknown actions and wrong resource types before deployment.
- Generate policies from CloudTrail activity or the console's policy editor, which auto-completes action names.
- Test with `aws iam simulate-principal-policy` for each action the application needs.
- Prefer wildcards on a verb family (for example `s3:Get*` on one bucket) only when you truly mean all of them. A wildcard hides typos by design, but it also over-grants.
