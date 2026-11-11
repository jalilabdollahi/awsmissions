# Solution

The function is configured for `python3.6`, which Lambda no longer supports, so it cannot even start a container. Only the configuration needs to change; the code and handler stay as they are.

1. Look at what is configured:

```bash
aws lambda get-function-configuration --function-name ledger-month-close \
  --query '[Runtime,Handler]'
```

2. The source uses `match` statements and `tuple[str, int]`, so it needs Python 3.10 or newer. Pick a currently supported one:

```bash
aws lambda update-function-configuration \
  --function-name ledger-month-close \
  --runtime python3.12
```

3. Invoke it to confirm:

```bash
aws lambda invoke --function-name ledger-month-close \
  --cli-binary-format raw-in-base64-out \
  --payload '{"entries":[{"account":"4000","amount_cents":100,"kind":"credit"}]}' out.json
```
