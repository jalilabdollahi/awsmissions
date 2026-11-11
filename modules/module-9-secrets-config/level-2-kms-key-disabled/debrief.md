# Debrief: a disabled key is a reversible kill switch

KMS keys move through states, and the state decides whether cryptographic operations work:

| State | Encrypt/Decrypt | Notes |
|---|---|---|
| `Enabled` | yes | normal |
| `Disabled` | no (`DisabledException`) | reversible with `enable-key` |
| `PendingDeletion` | no (`KMSInvalidStateException`) | reversible with `cancel-key-deletion` until the waiting period (7-30 days) ends |
| deleted | no, permanently | every ciphertext under it becomes unrecoverable |

**Why disabling is a good safety net.** Instead of deleting a key you think is unused, disable it, watch for failures for a few weeks, and only then schedule deletion. Here the "unused" key was still in use, so the failure showed up as a clear, fixable error.

**Why a new key would not have helped.** Decrypt does not take a key ID for symmetric keys: the ciphertext carries the identity of the key that produced it. Changing what an alias points to affects only *new* encryptions.

**In real life**
- Do not infer "unused" from the absence of a recent `Encrypt` call. Look at CloudTrail `Decrypt` events, and at the services (S3, EBS, RDS, Secrets Manager) that use the key on your behalf.
- Create a CloudWatch alarm on KMS `DisabledException`/`KMSInvalidStateException` errors in CloudTrail so someone notices within minutes.
- Use an IAM policy or SCP to restrict `kms:DisableKey` and `kms:ScheduleKeyDeletion` to a small admin role.
