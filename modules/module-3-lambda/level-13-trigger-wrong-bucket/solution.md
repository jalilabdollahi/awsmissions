# Solution

The trigger configuration is correct, it is just attached to the wrong bucket. Moving it takes two steps, and forgetting the first one leaves test data flowing into the real ledger.

1. Read the existing configuration from the staging bucket (the workspace has the same document as `notification.json`):

```bash
aws s3api get-bucket-notification-configuration --bucket marlowe-invoices-staging
```

2. Remove the trigger from staging by putting an empty configuration:

```bash
aws s3api put-bucket-notification-configuration --bucket marlowe-invoices-staging \
  --notification-configuration '{}'
```

3. Apply the same configuration (with its `.pdf` suffix filter) to the production bucket:

```bash
aws s3api put-bucket-notification-configuration --bucket marlowe-invoices-prod \
  --notification-configuration file://notification.json
```

The Lambda permission for the production bucket is already in place.
