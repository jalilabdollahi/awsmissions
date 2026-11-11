# Debrief: String, StringList and SecureString

| Type | Stored as | Use for |
|---|---|---|
| `String` | plain text | hosts, flags, timeouts |
| `StringList` | comma separated plain text | lists of IDs |
| `SecureString` | encrypted with KMS | tokens, passwords, connection strings with credentials |

A SecureString is encrypted with the AWS-managed key `alias/aws/ssm` by default. For anything important, use a **customer-managed key** (`--key-id alias/your-key`): you control the key policy, can audit every `Decrypt` in CloudTrail, can restrict who may read the data (a caller needs both `ssm:GetParameter` and `kms:Decrypt`), and can disable the key as an emergency stop. AWS-managed keys cannot be shared across accounts and give you none of those controls.

**Overwriting and versions.** Every `put-parameter --overwrite` creates a new version; old versions are kept in `get-parameter-history` (so the *plaintext* version stays reachable there for a while: delete the parameter and recreate it, or rotate the key material, if the value has already leaked). Callers that read `name:1` still get the old version; the default is the latest.

**Reading.** `get-parameter` hides the value of a SecureString unless `--with-decryption` is passed in real AWS; this emulator returns it regardless, so do not rely on that behaviour when testing.

**Leave simple settings simple.** Encrypting everything adds KMS costs and breaks tools that cannot decrypt. Classify parameters, and encrypt the sensitive ones.

**Rotate after exposure.** Converting the type protects the value from now on, but it was already readable in plain text. Treat the old API key as compromised and rotate it with the processor.
