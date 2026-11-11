# Solution

The key is stored as `String`. A parameter's type cannot be changed in place, but `put-parameter --overwrite` writes a new version with a new type, so the same name now holds an encrypted value.

```bash
aws ssm get-parameter --name /harrier/payments/api-key --query Parameter.Value --output text

aws ssm put-parameter --name /harrier/payments/api-key \
  --type SecureString --key-id alias/harrier-config \
  --value hk_live_77Q2xvNdw --overwrite
```

`check` verifies type `SecureString`, the key alias, that the decrypted value is unchanged, that the parameter is at version 2 or later, and that `timeout-ms` is still a plain `String`.
