# Debrief: access logs are delivered by a service, so the target bucket must trust it

S3 server access logging records requests (requester, operation, key, status, bytes) as log objects written *by the S3 logging service* into a target bucket. Nothing is recorded until you enable it, and records cannot be recovered retroactively, which is why last Tuesday's downloads are gone.

**What delivery needs**
- A target bucket in the same Region and account (a dedicated one, never the source itself: each log write is itself a request and would generate more logs forever).
- A bucket policy letting `logging.s3.amazonaws.com` perform `s3:PutObject` on the log keys. Without it, enabling logging succeeds but no logs ever arrive, one of the quietest failures in AWS.
- A `TargetPrefix` to keep logs from several sources apart.

**Details to know**
- Delivery is best-effort and usually delayed by minutes to hours.
- Add a condition on `aws:SourceArn` and `aws:SourceAccount` so only your bucket can write via the service principal.
- Log objects are cheap but add up: give the log bucket a lifecycle rule that expires or transitions them.

**In real life**
- For security investigations, CloudTrail data events give structured, near-real-time object-level audit and are usually the better tool. Access logs are a free, best-effort supplement.
- Enable logging when you create the bucket, not after the incident.
