# Solution

1. **Auditor's permission.** `assume-bridge` allows `sts:AssumeRole` on `ferro-audit-brigde` (typo). Replace the Resource with `arn:aws:iam::000000000000:role/ferro-audit-bridge`. A `*` here would let the auditor try the break-glass admin role.
2. **Bridge trust policy.** The `sts:ExternalId` condition is `ferro-ext-2025`; the agreement is `ferro-ext-2026`. Update the trust policy with `aws iam update-assume-role-policy`, keeping the principal and the condition.
3. **Reader trust policy.** The reader trusts `role/ferro-audit-bridge-v1`, the bridge's old name. Change the principal to `role/ferro-audit-bridge`.
4. **Reader permission.** `read-2026` names the bucket `ferro-ledger-archives`. Use `arn:aws:s3:::ferro-ledger-archive/2026/*`.

`check` actually assumes each hop in turn (user, bridge with ExternalId, reader), reads `2026/q3.csv`, and confirms that: assuming the bridge without or with a wrong ExternalId fails, the break-glass role cannot be assumed, and the 2025 prefix cannot be read.
