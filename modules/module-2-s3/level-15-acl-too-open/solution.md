# Solution

ACL grants live in three places here: the bucket ACL and each object's own ACL. Both must be cleaned, and the bucket needs a guard so it cannot happen again.

1. Look at the grants:

```bash
aws s3api get-bucket-acl --bucket sunrise-photos
aws s3api get-object-acl --bucket sunrise-photos --key galleries/smith-wedding/001.jpg
aws s3api get-bucket-ownership-controls --bucket sunrise-photos
```

2. Put the guard in place (either block public ACLs, or set ownership to `BucketOwnerEnforced`, which disables ACLs entirely):

```bash
aws s3api put-public-access-block --bucket sunrise-photos \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

3. Reset the grants to private, on the bucket and on every object:

```bash
aws s3api put-bucket-acl --bucket sunrise-photos --acl private
aws s3api put-object-acl --bucket sunrise-photos --key galleries/smith-wedding/001.jpg --acl private
aws s3api put-object-acl --bucket sunrise-photos --key galleries/smith-wedding/002.jpg --acl private
```

`renderer-app` is unaffected: it reads through its IAM policy, not through ACLs. The validator lists every object's ACL to check none is public.
