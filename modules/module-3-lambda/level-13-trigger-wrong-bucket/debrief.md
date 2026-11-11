# Debrief: triggers belong to the bucket, and clones copy wiring

An S3 trigger lives in the *bucket's* notification configuration, not on the function. That is why a function can be invoked by any number of buckets, and why the function's own configuration gives no hint of who calls it. The two fingerprints you can examine are:

- `aws s3api get-bucket-notification-configuration --bucket X`: what bucket X sends where.
- `aws lambda get-policy --function-name F`: which buckets (via `SourceArn`) are allowed to call F.

In this story the clone copied the *function ARN* of the production extractor into the staging bucket's configuration. That is the dangerous kind of mistake: no error, just a quiet leak of test documents into production data, and a hole where real data should be.

**Moving a trigger is a two-sided change.** Add it to the right bucket, remove it from the wrong one. `put-bucket-notification-configuration` replaces the full document, so `'{}'` clears all notifications on that bucket (check there is nothing else configured first).

**The extractor is deliberately environment-agnostic**: the ledger key contains the bucket name, which is how the checker tells staging and production records apart. Production-grade setups go further: separate accounts for staging and production, and functions per environment, so a mis-wired ARN cannot cross the boundary.

**In real life**
- Include the environment in every resource name, and let IaC (not hand-edited JSON) create bucket notifications, so a clone parameterises them.
- CloudTrail's `PutBucketNotification` events tell you who changed a trigger and when.
- Lambda's `SourceArn` condition on the permission is your second line of defence: if the staging bucket had never been granted invoke rights, the leak could not have happened.
