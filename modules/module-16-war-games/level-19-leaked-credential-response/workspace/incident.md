# SEC-INC-0402 - Build credentials found in a public repository

Cinder Games (indie studio, launcher + store). Reported by a secret-scanning
service at 11:48 and confirmed by a second scanner.

## The alert
> Active AWS access key `AKIA...` for IAM user `cg-build-bot` was committed to
> the public repository `cinder/launcher-tools` 19 days ago and is
> still valid. The exact key id and secret are recorded in SSM parameter
> `/cinder/forensics/leaked-key` (JSON `{"id": "...", "secret": "..."}`).

## What `cg-build-bot` is for
The CI pipeline uploads game builds to `s3://cg-build-artifacts`. CI reads its
credentials from the SSM parameter `/cinder/ci/build-bot-credentials`
(JSON `{"id": "...", "secret": "..."}`) at the start of every job. Tonight's
release build must still be able to upload.

## What the forensic review found
- The key was used from an unfamiliar network 6 days ago.
- Within minutes of that use, a new IAM user `cg-support-sync` appeared with
  administrator rights and its own access key, and a new role `cg-audit-helper`
  that trusts a foreign account (999999999999). Neither is on the architecture
  diagram. Treat both as attacker persistence.
- `cg-build-bot` carries a very broad inline policy (`s3:*` and `iam:*` on
  everything), which is how the attacker was able to create those identities.
- `cg-player-data` holds player records and must never be reachable by the
  build bot.

## Constraints
- Do not delete `cg-build-bot` (CI depends on the user) or other staff users
  such as `cg-dev-alice`.
- Order matters: if you kill the old key before CI has a new one, tonight's
  release is blocked; if you leave the old key live, the attacker keeps access.
