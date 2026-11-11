# Solution

The two parameters the service reads simply do not exist. The values live in the secret `corvid/checkout/db-credentials`.

```bash
aws secretsmanager get-secret-value --secret-id corvid/checkout/db-credentials --query SecretString --output text

aws ssm put-parameter --name /corvid/checkout/db-host --type String --value checkout-db.corvid.internal
aws ssm put-parameter --name /corvid/checkout/db-port --type String --value 5433
```

`check` assumes the `corvid-checkout` role, reads both parameters through it and compares them with the values in the secret.
