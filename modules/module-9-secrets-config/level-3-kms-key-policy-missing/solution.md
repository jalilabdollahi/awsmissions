# Solution

The key policy contains a single statement, for `key-admin`, covering administrative actions only. KMS evaluates the key policy first; with no statement for the writer role (and no delegation to the account root), the role's IAM policy cannot help it.

1. Read the policy and find the key ID:

```bash
aws kms describe-key --key-id alias/orbit-reports
aws kms get-key-policy --key-id <KeyId> --policy-name default
```

2. Add a usage statement for the role to `key-policy.json` (`edit`), keeping the administrator statement:

```json
{
  "Sid": "AllowReportWriterToUseTheKey",
  "Effect": "Allow",
  "Principal": { "AWS": "arn:aws:iam::000000000000:role/orbit-report-writer" },
  "Action": ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"],
  "Resource": "*"
}
```

3. Install it:

```bash
aws kms put-key-policy --key-id <KeyId> --policy-name default --policy file://key-policy.json
```

`check` parses the stored key policy: the role (or the account root, if you used the standard delegation statement) must be allowed to encrypt, decrypt and generate data keys; `key-admin` must still administer the key; nothing may be open to `*`; and the writer must not hold `kms:*`. It also runs an encrypt/decrypt round trip as the role.
