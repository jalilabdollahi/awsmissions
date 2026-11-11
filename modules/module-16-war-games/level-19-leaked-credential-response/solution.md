# Solution

1. **Recover.** `aws iam create-access-key --user-name cg-build-bot` (a user may hold two keys), then overwrite the SecureString parameter `/cinder/ci/build-bot-credentials` with the new `{"id","secret"}` JSON so CI keeps working.
2. **Contain.** Delete (or deactivate) the leaked key: its id is in `/cinder/forensics/leaked-key`. Leave that parameter in place; it is evidence.
3. **Eradicate.** Delete `cg-support-sync`: first its access key(s), then detach `AdministratorAccess`, then `delete-user`. Delete role `cg-audit-helper`: detach `AdministratorAccess`, then `delete-role`.
4. **Harden.** Replace `ci-everything` with a policy that allows `s3:PutObject`/`s3:GetObject` on `arn:aws:s3:::cg-build-artifacts/*` only.

`check` really tries the leaked key (must fail), uploads a build with the credential found in the pipeline's parameter (must work), confirms the hidden user and role are gone, and uses the new credential to try to read `cg-player-data` and list IAM users (both must be denied). It also makes sure `cg-build-bot` and `cg-dev-alice` still exist.
