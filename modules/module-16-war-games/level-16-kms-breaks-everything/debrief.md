# Debrief: INC-7702, the key that looked idle

## Root causes
1. **Scheduled deletion.** Cleanup tooling judged the key unused from CloudWatch metrics. A key that only decrypts data at rest has no traffic until somebody reads the data. A key `PendingDeletion` rejects every operation with a state error.
2. **Rotation off.** Not the cause of the outage, but compliance required it and it had been missed.
3. **Alias typo in function configuration.** `alias/vl-patient-note` does not exist, so even a healthy key could not be found by the function.
4. **IAM policy about the wrong key, and incomplete.** The role was granted `kms:Decrypt` on last year's key; the function also calls `kms:Encrypt`. IAM policies tied to key ARNs silently stop applying when a key is replaced.

## Timeline
- 03:00 the hygiene job schedules deletion with a 7-day window.
- 07:40 clinicians cannot open notes. First error: `KMSInvalidStateException`.
- 08:10 someone enables the key, which is refused in that state; the second error is the alias, then the IAM error.

## What the window gave us
Scheduling deletion is the safety net: nothing is destroyed for 7 to 30 days, and `cancel-key-deletion` brings the key back (as Disabled, deliberately, so you must opt in to using it). Once the window ends, the key material is gone and every ciphertext under it is unrecoverable.

## Lessons
- Never delete KMS keys based on usage metrics. Require an owner tag and a data-inventory check, and prefer disabling a key first and waiting through a full business cycle.
- Alarm on `CreateKey`/`ScheduleKeyDeletion`/`DisableKey` CloudTrail events, and give them a human approval step.
- Reference keys by alias in application config but by ARN in IAM, and re-check both after any key change.
- Grant KMS permissions per operation and per key; a role that can decrypt another team's key is a data-sharing incident waiting to happen.
