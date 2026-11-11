# INC-7702 - Patient notes unreadable after the "cloud hygiene" sweep

Vaultline Clinics, clinical-records platform. Severity: SEV-1 (clinicians cannot open notes).

## What happened
At 03:00 the monthly cloud-hygiene job swept the account for "unused" KMS
keys. It did not understand that the key behind the alias
`alias/vl-patient-notes` is used only when a note is *opened*, so it looked idle
for 30 days and was scheduled for deletion. At 07:40 clinicians started getting
"Internal error" when opening notes.

## How a note is opened
Lambda `vl-note-reader` loads the encrypted note from DynamoDB `vl-vault`
(item `n-1` is the one the clinic opens first), decrypts it with KMS, and
re-encrypts the plaintext for the audit archive using the key alias in its
`KEY_ALIAS` setting. It runs as role `vl-reader-role`. The on-call user
`vl-oncall` can assume that role.

## Facts and constraints
- The ciphertext in `vl-vault` was produced with the key behind
  `alias/vl-patient-notes`. Re-keying is NOT an option: those notes have to
  stay readable.
- A previous key, `alias/vl-notes-2024`, was retired last year. The reader's role
  policy was never updated and still references it.
- The same account holds `alias/vl-billing`, owned by the finance team. The
  reader must never be able to use it.
- Compliance (HIPAA control 7.3): automatic annual rotation must be enabled
  on the patient-notes key.
- The sweep job's author says "sorry, it only checks CloudWatch usage metrics".

## Verification hint
Opening note `n-1` through the function is the acceptance test; the function
should return the plaintext note.
