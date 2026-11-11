# Debrief: deleting a secret is a two-step process

`delete-secret` has two modes:

- **With a recovery window** (default 30 days, minimum 7): the secret is marked for deletion and becomes unreadable, but nothing is destroyed. `restore-secret` brings it back intact, including all versions and staging labels.
- **`--force-delete-without-recovery`**: immediate and permanent. No window, no undo.

During the window the *name* is still reserved, so you cannot create a new secret with it; that is why "just recreate it" is not an option, and why the exact error message ("marked for deletion") is more useful than a plain "not found".

**What the error looks like**
| Situation | Error |
|---|---|
| never existed / force-deleted / window expired | `ResourceNotFoundException: Secrets Manager can't find the specified secret` |
| pending deletion | `InvalidRequestException: ... marked for deletion` |

**In real life**
- Keep the recovery window at the default or longer for production secrets, and alert on `DeleteSecret` in CloudTrail.
- Deny `secretsmanager:DeleteSecret` for application roles, and deny `--force-delete-without-recovery` outright with a condition on `secretsmanager:ForceDeleteWithoutRecovery`.
- A clean-up script that deletes secrets "not used in 90 days" should check `LastAccessedDate` from `describe-secret` and tag secrets it must never touch.
- Pending deletions still cost nothing extra but show up in `list-secrets --include-planned-deletion`.
