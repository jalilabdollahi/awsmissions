# Solution

S3 only emits events for a bucket that has a notification configuration, and this bucket has none: the queue is fine, S3 just never sends anything.

1. Confirm:

```bash
aws s3api get-bucket-notification-configuration --bucket acornpay-invoices    # empty
aws sqs get-queue-attributes --queue-url $AWS_ENDPOINT_URL/000000000000/invoice-intake --attribute-names QueueArn
```

2. Fill in `notification.json` (`edit`):

```json
{
  "QueueConfigurations": [
    {
      "Id": "pdf-invoices-to-robot",
      "QueueArn": "arn:aws:sqs:us-east-1:000000000000:invoice-intake",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": { "Key": { "FilterRules": [
        { "Name": "prefix", "Value": "inbox/" },
        { "Name": "suffix", "Value": ".pdf" }
      ] } }
    }
  ]
}
```

3. Apply:

```bash
aws s3api put-bucket-notification-configuration --bucket acornpay-invoices \
  --notification-configuration file://notification.json
```

The validator uploads `inbox/*.pdf`, `inbox/*.txt` and `archive/*.pdf` as `scanner-svc` and reads the queue: only the first must produce a message.
