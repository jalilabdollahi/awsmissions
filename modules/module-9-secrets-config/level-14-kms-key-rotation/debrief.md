# Debrief: manual rotation moves the problem, automatic rotation removes it

KMS offers two very different things under the word "rotation".

**Automatic rotation** (`enable-key-rotation`). KMS generates new key material for the *same key* on a schedule (default every year) and keeps all older material internally. The key ID, ARN, aliases and policies never change; old ciphertext still decrypts; new ciphertext uses the newest material. Applications do nothing. It is the right default for symmetric customer-managed keys.

**Manual rotation.** You create a *new key*, repoint the alias, and decide what happens to data under the old key. This is necessary for asymmetric keys, imported key material or keys in external key stores, and sometimes for compliance reasons. But every ciphertext remembers its key, so the old key must stay enabled for as long as old data exists, or the data must be re-encrypted. Disabling or deleting the old key at the end of the runbook, as happened here, turns an old ciphertext into an incident, or into permanent data loss if the key is deleted.

**ReEncrypt.** `kms:ReEncrypt` decrypts under one key and encrypts under another entirely inside KMS, so the plaintext never leaves the service. It is how you migrate S3 object keys, stored blobs and data keys. Encryption context must be supplied for source and destination, and the new ciphertext is only decryptable with the *destination* context you gave.

**A safe manual rotation runbook**
1. Create the new key, tag it, point the alias at it (new writes use the new key).
2. Re-encrypt existing data (or let it age out).
3. Watch CloudTrail `Decrypt` events for the old key until they stop.
4. Disable the old key and wait weeks.
5. Only then schedule deletion, with the longest waiting period (30 days). Deletion can be cancelled until the end of the window.

**Why encryption context matters.** It is authenticated additional data: it is not secret but must match exactly on decrypt. It lets you bind a ciphertext to its purpose (`dataset=atlas-archive`) and shows up in CloudTrail, which makes audit trails readable.
