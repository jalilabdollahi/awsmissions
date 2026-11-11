# Solution

A function pins an exact **layer version**, not a layer. `txn-scorer` is attached to `riskkit-core:1`, the pre-2024 rules, which have no `velocity_penalty`, so `from riskkit.rules import ... velocity_penalty` fails at import time.

1. Look at what the function uses and what versions exist:

```bash
aws lambda get-function-configuration --function-name txn-scorer --query 'Layers[].Arn'
aws lambda list-layer-versions --layer-name riskkit-core \
  --query 'LayerVersions[].[Version,Description,LayerVersionArn]' --output table
```

2. Version 2 is the 2024 ruleset. `--layers` **replaces the whole list**, so pass the new riskkit version and the existing tracing layer:

```bash
aws lambda update-function-configuration --function-name txn-scorer --layers \
  arn:aws:lambda:us-east-1:000000000000:layer:riskkit-core:2 \
  arn:aws:lambda:us-east-1:000000000000:layer:tracekit-logging:1
```
