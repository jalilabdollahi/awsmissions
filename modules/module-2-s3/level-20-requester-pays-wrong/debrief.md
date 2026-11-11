# Debrief: who pays for a request is a bucket-level switch with sharp edges

Normally the **bucket owner** pays for storage and for the requests and data transfer out of the bucket. With **Requester Pays** the *requester* pays for requests and data transfer, while the owner still pays for storage. It is built for sharing large public datasets without footing the bandwidth bill.

**Why it breaks automation**
- Requester Pays buckets reject anonymous access: the requester must be authenticated so AWS knows whom to bill.
- Every call must carry `x-amz-request-payer: requester` (`--request-payer requester` in the CLI, `RequestPayer` in SDKs). Without it S3 answers `403 AccessDenied`. A partner's scripts that never heard of the header suddenly fail, or, if they were updated, silently start generating charges.
- Pre-signed URLs for such a bucket must include the header as well.

**The mistake pattern**
The script was written for one bucket and applied to a wildcard. Account-wide automation needs an allow-list, and a dry run that prints what it would change.

**In real life**
- Audit with a loop like the one in the solution, or AWS Config's managed rules.
- Cost visibility: use cost allocation tags or S3 Storage Lens to see who generates transfer charges before you decide on Requester Pays.
- If a partner needs access, grant it with a bucket policy and let them pay via Requester Pays only when that is the agreement. Never make it a surprise.
- Local emulators may not reject requests without the header, so test this against a real bucket before rolling a change out.
