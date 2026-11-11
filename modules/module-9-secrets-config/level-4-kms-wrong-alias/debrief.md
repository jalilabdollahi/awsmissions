# Debrief: an alias is a pointer you can aim at the wrong thing

`CreateAlias` binds a name to a key; `UpdateAlias` rebinds it. Applications that use aliases get the flexibility to rotate keys without redeploying, but also inherit a risk: **whoever can update the alias controls which key every caller uses**.

What went wrong here is subtle because nothing failed. Encryption through the alias still worked, just under the wrong key. The symptoms appeared elsewhere, in a consumer whose permissions are tied to the production key.

**Telling keys apart**
- Descriptions and tags (`env`, `service`, `owner`) are the only human-readable identity a key has. Fill them in when the key is created.
- `aws kms decrypt` on a known ciphertext returns the `KeyId` that produced it, a quick way to find out which key some data belongs to.
- CloudTrail records `UpdateAlias` with the old and new target; look there to learn who moved it.

**Rules of thumb**
- Aliases name a *purpose* (`orders-prod`), never a person or a date.
- One environment, one key. Never point a staging alias at a production key or the reverse; an alias is not a security boundary, but separate keys are.
- Restrict `kms:UpdateAlias`/`kms:CreateAlias` using IAM conditions on `kms:ResourceAliases` or the alias ARN, since permission on the alias and on the key are separate checks.
- Existing ciphertext is unaffected by alias moves. Only *new* encryptions follow the alias, so a wrong target creates a mixed population of data under different keys that is painful to untangle later.
