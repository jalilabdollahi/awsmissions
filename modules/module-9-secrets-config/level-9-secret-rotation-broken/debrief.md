# Debrief: rotation is a Lambda plus a schedule

Automatic rotation needs three things to work:

1. **A rotation function.** Secrets Manager invokes it with `Step` set to `createSecret`, `setSecret`, `testSecret` and `finishSecret`, passing the secret ARN and a client request token. For RDS and other supported databases AWS provides ready-made templates.
2. **Permission to invoke it.** The function's resource policy must allow `secretsmanager.amazonaws.com` to call it (the console or SAM template adds this; with the CLI you add it with `lambda add-permission`). The function's own role needs access to the secret and, for managed rotation, network access to the database.
3. **A schedule.** `AutomaticallyAfterDays` or a cron-style `ScheduleExpression`, plus an optional `Duration` window.

The configuration is stored as a plain ARN, so a deleted or renamed function leaves a **silently broken rotation**: nothing alerts you until the audit finds a 6-month-old password. That is why the check in this mission looks at `RotationLambdaARN` *and* confirms the function exists.

**How `rotate-secret` behaves**
- With a new `--rotation-lambda-arn` it replaces the rotator and the schedule, and starts an immediate rotation unless you pass `--no-rotate-immediately`. A rotation that is still in progress blocks the next `rotate-secret` call.
- With only `--rotation-rules` it changes the schedule.
- To turn automatic rotation off use `cancel-rotate-secret`.

**In real life**
- Alarm on rotation failures: CloudTrail records `RotationFailed`-style events, and CloudWatch metrics for the function's errors show a broken rotator quickly.
- Prefer managed rotation or alternating-users strategy for databases so that credentials in flight do not break.
- Never share one rotator across unrelated databases unless it is written for it.
- AWS Config rule `secretsmanager-rotation-enabled-check` and `secretsmanager-scheduled-rotation-success-check` catch exactly this class of drift.
