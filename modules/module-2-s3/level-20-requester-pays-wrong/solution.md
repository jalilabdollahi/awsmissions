# Solution

The setting is per bucket, so audit all Ridgeline buckets and revert the wrong ones.

1. List the buckets and their payer:

```bash
for b in $(aws s3api list-buckets --query 'Buckets[?starts_with(Name, `ridgeline-`)].Name' --output text); do
  echo "$b: $(aws s3api get-bucket-request-payment --bucket $b --query Payer --output text)"
done
```

2. Revert every bucket that should not be on Requester Pays (`ridgeline-partner-feeds` and `ridgeline-internal-reports`):

```bash
aws s3api put-bucket-request-payment --bucket ridgeline-partner-feeds \
  --request-payment-configuration Payer=BucketOwner
aws s3api put-bucket-request-payment --bucket ridgeline-internal-reports \
  --request-payment-configuration Payer=BucketOwner
```

Leave `ridgeline-open-data` as it is. The validator audits every `ridgeline-` bucket, so reverting only the partner bucket is not enough, and reverting all of them is wrong.
