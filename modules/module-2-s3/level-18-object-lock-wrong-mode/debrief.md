# Debrief: GOVERNANCE is a speed bump, COMPLIANCE is a wall

S3 Object Lock offers two retention modes:

| | GOVERNANCE | COMPLIANCE |
|---|---|---|
| Normal users | cannot overwrite or delete the version | cannot overwrite or delete the version |
| Users with `s3:BypassGovernanceRetention` (+ the header) | can delete or shorten retention | **cannot**, whatever they have |
| Root user | can bypass | **cannot** |
| Retention can be shortened | yes, with bypass | **never** |
| Retention can be extended | yes | yes |
| Mode can be changed | to COMPLIANCE, yes | **no** |

That is why the regulator rejected the setup: the very people who could be accused of tampering held the key to the lock.

**Per-version, not per-key**
Retention belongs to a version. Locking `2025-fy.csv` once does not protect its earlier version. You have to enumerate versions and set each one (or use S3 Batch Operations at scale).

**Defaults only look forward**
`DefaultRetention` is applied to objects written after it is set, and only if the request carries no explicit lock settings. Existing locks do not change.

**One-way door**
COMPLIANCE cannot be undone: an object locked for 7 years will be billed for 7 years, and the only way to stop paying is closing the AWS account. Test with GOVERNANCE first, and think about storage class before you lock.

**In real life**
- Object Lock requires versioning (which `create-bucket --object-lock-enabled-for-bucket` turns on automatically).
- It underpins SEC 17a-4(f), FINRA and CFTC records requirements; AWS publishes an assessment for it.
- Use Legal Hold (`put-object-legal-hold`) for open-ended holds without a date.
