# Solution

1. **Key state.** The hygiene sweep scheduled the key for deletion (`PendingDeletion`). While in that state the key cannot be used. `aws kms cancel-key-deletion` restores it but leaves it `Disabled`, so follow with `aws kms enable-key`.
2. **Rotation.** `aws kms enable-key-rotation --key-id <id>` (control 7.3).
3. **Function configuration.** `KEY_ALIAS` is `alias/vl-patient-note` (missing `s`). Set it to `alias/vl-patient-notes`.
4. **Role policy.** The KMS statement allows only `kms:Decrypt`, on the retired key. Replace it with `kms:Decrypt` and `kms:Encrypt` on the patient-notes key's ARN (get the id with `describe-key`). Do not use `Resource: "*"`: that would let the role decrypt finance's billing data.

`check` verifies the key state and rotation, resolves the alias, asks KMS as the role (encrypt then decrypt) and confirms it still cannot decrypt the billing ciphertext, then invokes `vl-note-reader` on note `n-1`.
