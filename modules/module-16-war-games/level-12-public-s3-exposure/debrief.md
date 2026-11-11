# Debrief: SEC-INC-0719, data exposure

## Root causes
| # | Where | What |
|---|---|---|
| 1 | Bucket policy | `Principal: "*"` Allow added as a "quick share" and never removed. This is the one the researcher found: no credentials required in real AWS. |
| 2 | Group policy | `ardent-staff` given the entire bucket "for the quarter-end"; the temp contractor inherits it |
| 3 | User policies | `partners/*` instead of `partners/<name>/*`; each partner can read the other's data |

## Timeline
- Two weeks ago: quick share added (1); quarter-end access given to staff (2); partner policies written broadly (3).
- 08:55: researcher reports unauthenticated download of `pii/customers.csv`.
- 09:30: first reflex is "block public access and delete the bucket policy", which would have taken analysts down while leaving 2 and 3 untouched.

## Why three layers matter
S3 permits a request if *any* applicable policy allows it and none denies it: identity policies of the user, policies of the user's groups, and the bucket policy. Locking one door says nothing about the others. The right incident approach is to enumerate every grant that applies to the sensitive prefix and check each one.

In real AWS, S3 Block Public Access would also have neutralised the `Principal: "*"` statement, and it should be enabled on every account by default. The lesson stands even with it: the two internal over-grants are invisible to Block Public Access because the users are authenticated.

## Lessons
- Enable account-level S3 Block Public Access and use IAM Access Analyzer for S3 to list public and cross-account grants.
- "Temporary" grants need an expiry: a ticket, an owner and a calendar entry. Better, use a condition (`aws:CurrentTime`) or a separate role with a short session.
- Scope identity policies to a prefix per partner. Where partners multiply, use S3 Access Points or `${aws:username}` policy variables so a new partner cannot be mis-scoped.
- Contain without outage: confirm the business flows still work after each change, exactly as the retest does.
