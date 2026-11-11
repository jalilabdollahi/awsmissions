# Solution

`alias/atlas-data` now points at the 2024 key, but the three archive records were encrypted under the 2021 key, which the runbook disabled. Decrypt works from the ciphertext's embedded key ID, so it hits the disabled key. The data must be migrated to the new key, then the old key retired again.

1. Find the old key (description "Atlas archive key (2021, retired)") and enable it temporarily:

```bash
aws kms list-keys
aws kms describe-key --key-id <KeyId>
aws kms enable-key --key-id <old KeyId>
```

2. For each of the three records: decode the stored base64 to a file, re-encrypt under the current key (keeping the context), store the new base64:

```bash
aws ssm get-parameter --name /atlas/archive/record-1 --query Parameter.Value --output text | base64 -d > record.bin
aws kms re-encrypt --ciphertext-blob fileb://record.bin \
  --source-encryption-context dataset=atlas-archive \
  --destination-key-id alias/atlas-data \
  --destination-encryption-context dataset=atlas-archive \
  --query CiphertextBlob --output text
aws ssm put-parameter --name /atlas/archive/record-1 --type String --value '<new base64>' --overwrite
```

3. Retire the old key again and turn on automatic rotation for the current one:

```bash
aws kms disable-key --key-id <old KeyId>
aws kms enable-key-rotation --key-id <current KeyId>   # the key behind alias/atlas-data; this call does not accept aliases
```

`check` decrypts all three records (with the encryption context) and requires each to report the current key as its source, the old key to be disabled but not pending deletion, and rotation to be enabled on the current key.
