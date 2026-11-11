# Debrief: INC-2291, the manifest indexer

## What was actually wrong
| # | Layer | Fault |
|---|---|---|
| 1 | Role identity policy | No `s3:GetObject` - the role could list the bucket but not read objects |
| 2 | Bucket (resource) policy | `FreezeOldIndexer`, a Deny from the 03:40 scare, still blocked `PutObject` on `processed/*` |
| 3 | Lambda configuration | The 05:30 deploy set `MANIFEST_BUCKET=hv-manifest` |

## Timeline (as a postmortem would read)
- 03:40 - an engineer, worried about an unrelated alert, adds a Deny to the bucket policy to "freeze" the old indexer. No ticket, no expiry.
- 05:30 - deploy of the dashboard rewrites the function's environment with a typo.
- 06:12 - dispatch notices the empty tile. The first error everyone sees is `AccessDenied` on `GetObject`, which hides the other two faults behind it.
- Resolution - each hop is tested separately and fixed in the place where it lives.

## How AWS decided
For a same-account request S3 combines the principal's identity policies and the bucket policy: any explicit Deny wins; otherwise an Allow from either side is enough. That is why "the role has no GetObject" and "the bucket denies PutObject" are different bugs with the same symptom. A Lambda role is just a role: calling the same API as the role (`hv-oncall` assuming it) reproduces what the function sees, without waiting for a cold start.

## Lessons
- Fix one hop at a time and re-test. The first error masks the rest.
- Emergency Denies need an owner and an expiry; write them into the ticket and give the Sid a meaningful name.
- Scope fixes to the prefix you need. Granting `s3:*` on `*` would have "worked" and silently opened `hv-payroll-exports` to the indexer.
- Typos in environment variables are the most common Lambda failure after IAM. Keep config in code (IaC) so a deploy cannot silently diff.
