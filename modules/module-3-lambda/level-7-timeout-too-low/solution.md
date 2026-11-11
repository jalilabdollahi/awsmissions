# Solution

A page takes about 0.6 s and a quarterly statement has 12 pages, roughly 7 s of work. The function is configured to be killed after 3 s.

1. Check the configured timeout and reproduce the failure:

```bash
aws lambda get-function-configuration --function-name statement-renderer --query Timeout
aws lambda invoke --function-name statement-renderer --cli-binary-format raw-in-base64-out \
  --payload '{"customer":"ACME-0042","pages":12}' out.json && cat out.json
```

2. Raise the timeout to something comfortably above the work, but within the 29 second API limit (20 s here):

```bash
aws lambda update-function-configuration --function-name statement-renderer --timeout 20
```
