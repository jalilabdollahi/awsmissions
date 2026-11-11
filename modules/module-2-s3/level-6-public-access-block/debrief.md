# Debrief: Block Public Access is a guard rail above your policies

S3 Block Public Access (BPA) has four independent switches, evaluated on top of ACLs and bucket policies:

| Setting | What it does |
|---|---|
| `BlockPublicAcls` | rejects requests that would add a public ACL |
| `IgnorePublicAcls` | ignores any public ACL that already exists |
| `BlockPublicPolicy` | rejects `PutBucketPolicy` for policies that grant public access |
| `RestrictPublicBuckets` | limits access through an already-public policy to AWS principals in the account |

Here `BlockPublicPolicy` rejected the policy at save time. That is why the owner got Access Denied even though the JSON was perfectly valid. For a policy to actually serve the public, `RestrictPublicBuckets` must be off as well.

**The right way to open a bucket**
1. Relax only what the use case needs (here: the two *policy* switches). Leave the ACL switches on, because ACLs are the legacy way buckets get exposed by accident.
2. Scope the policy to a prefix. The intern's `bucket/*` would have published contract drafts to the whole internet.

**In real life**
- BPA exists at account level too; an account-wide block overrides bucket settings. Check both.
- For public websites and downloads, consider CloudFront with Origin Access Control instead. The bucket can then stay fully private.
- Never "fix" this by deleting the BPA configuration; that removes all four protections at once.
