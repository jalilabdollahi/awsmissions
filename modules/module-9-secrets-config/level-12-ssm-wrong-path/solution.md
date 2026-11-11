# Solution

The provisioning script wrote `db-host`, `db-user` and `db-password` under `/lattice/prod`, while the service (and its IAM policy) use `/lattice/production`.

1. Read the existing values:

```bash
aws ssm get-parameters-by-path --path /lattice/prod --recursive --with-decryption \
  --query 'Parameters[].[Name,Type,Value]' --output text
```

2. Create the same parameters at the expected names, keeping types:

```bash
aws ssm put-parameter --name /lattice/production/db-host --type String --value inventory-db.lattice.internal
aws ssm put-parameter --name /lattice/production/db-user --type String --value inventory_app
aws ssm put-parameter --name /lattice/production/db-password --type SecureString --value '<password>'
```

3. `check` reads the three production parameters as `lattice-svc`, compares the values, confirms the password is a `SecureString`, and verifies that `lattice-svc` still cannot read `/lattice/prod` and that the old parameters remain.
