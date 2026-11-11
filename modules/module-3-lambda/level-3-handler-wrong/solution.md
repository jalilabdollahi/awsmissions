# Solution

The package is fine; the configured entry point is not. Lambda was told to load `index.handler`, but the zip contains `relay.mjs`, and the function that does the real work is exported as `sign`.

1. Check what is configured and what the package contains (the same file is in your workspace):

```bash
aws lambda get-function-configuration --function-name webhook-relay --query Handler
grep export relay.mjs
```

2. The handler format is `<file name without extension>.<exported function>`. The file is `relay.mjs` and the signing function is `sign` (not `ping`, which only answers "alive"):

```bash
aws lambda update-function-configuration \
  --function-name webhook-relay \
  --handler relay.sign
```

3. Invoke it with a sample order and look for a `signature` in the response.
