# Solution

The role's trust policy names `ec2.amazonaws.com`, the service of the render box the role was copied from. Lambda is the service that must be trusted.

1. Read the current trust policy:

```bash
aws iam get-role --role-name lumen-thumb-scanner --query Role.AssumeRolePolicyDocument
```

2. In your workspace copy (`edit trust.json`) change only the service principal of the first statement to `lambda.amazonaws.com`. Leave the second statement for `ci-deployer` alone.

3. Replace the trust policy. This API swaps the whole document, which is why you edit the full file rather than writing a new one from memory:

```bash
aws iam update-assume-role-policy --role-name lumen-thumb-scanner \
  --policy-document file://trust.json
```

Do not delete and recreate the role: the inline `read-raw-uploads` policy would be lost, and the checker invokes the function to prove it still works.
