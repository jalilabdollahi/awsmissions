# Debrief: resource-based policies name their principals

An **identity policy** is attached to a user, group or role and says what that identity may do. A **resource-based policy** (S3 bucket policy, SQS queue policy, KMS key policy, Lambda resource policy, role trust policy) is attached to the resource and says who may use it, so it must contain a `Principal`.

Within one account, either side is enough: if the identity policy *or* the resource policy allows the request (and nothing denies it), it goes through. `proofreader` had nothing on the identity side, so the bucket policy was the only thing standing between them and the proofs. Across accounts, both sides must allow.

Two things went wrong at once:

- The `Principal` ARN did not match any user. A misspelled principal is accepted silently and simply never matches (just like a wrong trust policy).
- `ListBucket` is a **bucket-level** action (`arn:aws:s3:::bucket`), `GetObject` is **object-level** (`arn:aws:s3:::bucket/*`). One statement cannot serve both with one Resource.

**In real life**
- `aws s3api put-bucket-policy` replaces the whole policy, and the console warns when a policy would lock you out. If an Allow is not working, verify the principal with `aws iam get-user` / `get-role` first.
- Do not use `"Principal": "*"` in bucket policies unless it is deliberate public access, and combine it with conditions (`aws:PrincipalOrgID`, VPC endpoints). S3 Block Public Access can protect you from yourself.
- Remember that bucket policies are limited to 20 KB, and that explicit Deny in either policy always wins.
