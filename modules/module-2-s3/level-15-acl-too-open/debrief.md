# Debrief: ACLs are the legacy way to leak data

ACLs predate IAM. A bucket ACL and an object ACL can each grant READ to the `AllUsers` group (anyone on the internet) or `AuthenticatedUsers` (anyone with *any* AWS account). Because they sit on each object, they are easy to forget: changing the bucket ACL does not touch what the old script put on every object.

**Today's guard rails**
- **Object Ownership = BucketOwnerEnforced**: ACLs are disabled completely and `PutObjectAcl` fails. This is the default for new buckets and AWS's recommendation.
- **Block Public Access**: `BlockPublicAcls` refuses new public ACLs; `IgnorePublicAcls` makes S3 behave as if existing public ACLs were not there. Setting both is a safety net even when ACLs are still enabled.
- Ignoring a public ACL does not remove it. A scanner (and a future policy change) can still see it, so clean it as well.

**What happened**
The uploader script used `--acl public-read` per object. Fixing one level (the bucket ACL) would have left the photos public. The validator therefore walks every object.

**In real life**
- Run `aws s3api get-object-acl` across a bucket with a small loop, or use S3 Storage Lens / Access Analyzer for S3 to find exposure.
- Serve public galleries through CloudFront with Origin Access Control instead of public ACLs.
- Migrate legacy ACL users to bucket policies and IAM roles before you enforce bucket-owner ownership, or those writers will start failing.
