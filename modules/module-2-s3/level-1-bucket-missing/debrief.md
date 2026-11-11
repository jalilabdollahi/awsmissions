# Debrief: bucket names are global, exact, and unforgiving

`NoSuchBucket` means the name in the request does not match any bucket. S3 never guesses. A single missing letter is a different bucket, so the near-identical bucket created by the migration script was useless to the ingest service.

**What to remember**
- Bucket names are unique across every AWS account in a partition. If `harborline-manifests-2026` had been taken by someone else, `mb` would return `BucketAlreadyExists` and you would need a different name (and a config change).
- A name you own and have forgotten about returns `BucketAlreadyOwnedByYou` in us-east-1 and an error elsewhere.
- IAM policies reference buckets by ARN, which contains the name. A policy written for one name does nothing for another. Here it was right all along, which is why the fix needed no IAM change.

**In real life**
- Keep bucket names in one place (infrastructure as code or a parameter store) so applications and policies cannot drift apart.
- Use `aws s3api head-bucket --bucket NAME` in deploy scripts: it distinguishes "does not exist" (404) from "exists but you may not touch it" (403).
- Do not rely on "almost the same" names for staging and production. Put the environment in a predictable position in the name and make typos fail loudly.
