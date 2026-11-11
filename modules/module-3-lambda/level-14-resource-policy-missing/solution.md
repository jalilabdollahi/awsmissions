# Solution

Lambda functions carry their own **resource-based policy**. The contract says Cartwheel grants partner access there instead of editing the partner's IAM user. Right now that policy has no statement for ShipRight.

1. Look at the function's policy:

```bash
aws lambda get-policy --function-name rate-quote-engine
```

It does not exist yet (`ResourceNotFoundException`).

2. Add a statement for exactly that user and exactly that action:

```bash
aws lambda add-permission --function-name rate-quote-engine \
  --statement-id allow-shipright-invoke \
  --action lambda:InvokeFunction \
  --principal arn:aws:iam::000000000000:user/partner-shipright
```

3. Check the resulting policy with `aws lambda get-policy --function-name rate-quote-engine`. Do not use `--principal '*'`: FastLane would get in as well.
