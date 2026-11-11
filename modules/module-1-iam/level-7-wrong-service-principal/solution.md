# Solution

The trust policy was copied from an EC2 instance role, so it says `"Principal": {"Service": "ec2.amazonaws.com"}`: only the EC2 service may assume the role. A human IAM user is never an AWS service, so `sre-oncall` is refused.

1. Inspect it:

```bash
aws iam get-role --role-name sre-breakglass --query Role.AssumeRolePolicyDocument
```

2. In `trust-policy.json` (`edit`), replace the Principal with the on-call user:

```json
"Principal": { "AWS": "arn:aws:iam::000000000000:user/sre-oncall" }
```

3. Apply it:

```bash
aws iam update-assume-role-policy --role-name sre-breakglass --policy-document file://trust-policy.json
```

`check` assumes the role as `sre-oncall` and purges the queue, then confirms `sre-intern` is still rejected.
