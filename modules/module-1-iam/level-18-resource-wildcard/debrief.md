# Debrief: wildcards grow with your account

A `*` inside a resource ARN matches any characters, so `arn:aws:s3:::vantage-*/*` is really "objects in any bucket I will ever name vantage-something". That is dangerous in two ways:

1. **Today's accidents:** buckets that share the prefix but hold sensitive data (payroll, legal hold) are included.
2. **Tomorrow's accidents:** the next bucket someone creates with the prefix is covered automatically, with no review.

Over-permissive policies are hard to see because nothing is broken: the symptom is a scanner report, an audit finding or, worst case, an incident.

The fix is two kinds of narrowing:

- **Resources:** list the exact buckets (or a prefix that is truly unique to the app).
- **Actions:** separate read from write; the worker needs `GetObject` on inputs and `PutObject` on outputs, not both everywhere.

**In real life**
- IAM Access Analyzer can generate a least-privilege policy from CloudTrail activity and flag unused permissions.
- Use naming conventions that make safe wildcards possible (for example `app-render-*` owned by one team) and enforce them with SCPs or bucket-creation guardrails.
- `aws iam simulate-principal-policy` with several `--resource-arns` is a quick way to test what a policy reaches before you ship it.
- Review wildcards in every PR, as you would a `chmod 777`.
