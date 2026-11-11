# Solution

1. **Image.** Revision 1 pulls `registry.ledgerco.invalid/ledger-web:2026.11`; the mirror is unreachable, so the task stops with `TaskFailedToStart` ("failed to resolve reference"). The ticket says the public `nginx:alpine` image is acceptable for now.
2. **Environment.** The wrapper script exits with code 3 unless `DB_HOST` is set; the task definition sets `DATABASE_HOST`. Rename the variable to `DB_HOST` (value `ledger-db.internal`). Do not remove the guard from the command.
3. **Service.** Register the corrected definition as revision 2 (`describe-task-definition`, edit, `register-task-definition --cli-input-json`), then `update-service --task-definition ledger-web:2 --desired-count 2`.

`check` verifies the guard is still in the wrapper, starts a throwaway task from the service's current task definition to prove it comes up and stays up, and finally waits for the service to report two stable running tasks.
