# Solution

The `prod` alias points at version 5, which was never published (a typo in the promotion script). Fix the target, and choose it using the release notes.

1. List the versions and the alias:

```bash
aws lambda list-versions-by-function --function-name tax-calculator \
  --query 'Versions[].[Version,Description]' --output table
aws lambda get-alias --function-name tax-calculator --name prod
```

2. Version 2 is the one marked APPROVED; version 3 is an unapproved experiment (and `$LATEST` has the same code as 3). Point the alias at version 2:

```bash
aws lambda update-alias --function-name tax-calculator --name prod --function-version 2
```

3. Invoke through the alias, as checkout does:

```bash
aws lambda invoke --function-name tax-calculator:prod --cli-binary-format raw-in-base64-out \
  --payload '{"amount":123.45,"category":"books"}' out.json && cat out.json
```
