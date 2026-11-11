# Solution

The policy has three defects: it allows `ssm:GetParameters` but the task calls `ssm:GetParameter`; the Resource has a doubled slash (`parameter//kiln/prod/*`) so it matches no parameter; and nothing allows `kms:Decrypt` on the key that encrypts `/kiln/prod/db-password`.

1. Look up the key ARN:

```bash
aws kms describe-key --key-id alias/kiln-config --query KeyMetadata.Arn --output text
```

2. Fix `policy.json` (`edit`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadKilnProdConfig",
      "Effect": "Allow",
      "Action": ["ssm:GetParameter", "ssm:GetParameters"],
      "Resource": "arn:aws:ssm:us-east-1:000000000000:parameter/kiln/prod/*"
    },
    {
      "Sid": "DecryptKilnConfig",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "<key ARN>"
    }
  ]
}
```

3. Reapply:

```bash
aws iam put-role-policy --role-name kiln-task --policy-name kiln-task-config --policy-document file://policy.json
```

`check` reads both production parameters as the role, asks IAM whether the role may `kms:Decrypt` with the Kiln key (and not with another key), and verifies `/kiln/dev/queue-url` and `/kiln-admin/root-token` are still refused.
