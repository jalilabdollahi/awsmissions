# Debrief: keys and aliases are two different objects

A KMS **key** has an ID (a UUID) and an ARN. An **alias** is a separate resource, `alias/<name>`, that maps a friendly name to one key in one region. Applications should reference aliases:

- you can **repoint** an alias to a new key without changing application config,
- humans can read the name,
- IAM policies can match aliases with the `kms:ResourceAliases` condition key.

Because the alias is its own object, it can be missing, point at the wrong key, or outlive a deleted key. A `NotFoundException: Alias ... is not found` means the name resolves to nothing.

**Defaults worth knowing when you create a key**
- `KeySpec` defaults to `SYMMETRIC_DEFAULT` (AES-256-GCM) and `KeyUsage` to `ENCRYPT_DECRYPT`. Asymmetric and HMAC keys cannot be used for envelope encryption with most AWS services.
- Automatic rotation is **off** for customer-managed keys. Turning it on (`enable-key-rotation`) makes KMS create fresh key material about once a year while keeping old material so earlier ciphertexts still decrypt.
- Alias names cannot start with `alias/aws/`, which is reserved for AWS-managed keys.

**In real life** manage keys and aliases in infrastructure as code, tag keys with an owner and data classification, and give the key a meaningful description so people do not delete the "unused" one.
