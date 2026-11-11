# Solution

`PutBucketPolicy` is rejected because the bucket has **Block Public Access** with `BlockPublicPolicy=true`: S3 refuses to save any policy that grants access to `"*"`. Even the account owner is refused.

1. See the guard:

```bash
aws s3api get-public-access-block --bucket lumen-brand-assets
```

2. Relax only the two settings that stop a public *bucket policy*, and keep the ACL protections:

```bash
aws s3api put-public-access-block --bucket lumen-brand-assets \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false
```

3. Narrow the policy before you apply it. The intern's draft made the *whole bucket* public, including `private/`. Change the Resource to `arn:aws:s3:::lumen-brand-assets/public/*` and apply:

```bash
aws s3api put-bucket-policy --bucket lumen-brand-assets --policy file://public-read-policy.json
```

The validator downloads `public/logo.txt` and `private/agency-contract-draft.txt` as a user with no permissions, and checks that the ACL protections are still on.
