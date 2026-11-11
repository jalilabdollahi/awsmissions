# Solution

The rule's only target points at `harbor-ingest-staging`. A rule can have several targets, and each one is delivered independently, so the fix is to make the production queue the target and make sure no staging target remains.

```bash
aws events list-targets-by-rule --rule harbor-shipment-created
aws events remove-targets --rule harbor-shipment-created --ids ingest
aws events put-targets --rule harbor-shipment-created \
  --targets Id=ingest,Arn=arn:aws:sqs:us-east-1:000000000000:harbor-ingest-prod
```

Run `check`: it publishes a booking and verifies it arrives in prod and not in staging.
