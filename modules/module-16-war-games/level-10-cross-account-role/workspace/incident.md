# Audit engagement FM-2026-Q3: auditors cannot reach the ledger archive

Ashgrove Audit LLP is engaged by Ferro Mining to audit the Q3 ledger. Ferro's
cloud team set up a two-hop access path last week. On day one of fieldwork the
auditor's access fails.

## The agreed access path (from Ferro's security design, rev 4)

    ashgrove-auditor (IAM user, Ashgrove side)
          |  sts:AssumeRole  +  ExternalId "ferro-ext-2026"
          v
    ferro-audit-bridge (role)
          |  sts:AssumeRole  (role chaining; no ExternalId on this hop)
          v
    ferro-ledger-reader (role)  -->  read-only on s3://ferro-ledger-archive/2026/*

## Constraints from Ferro's CISO
- ExternalId is mandatory on hop 1. It protects against the confused-deputy
  problem, so it must not be removed even though it is "annoying".
- The auditor's user may assume the bridge role and nothing else. Ferro
  also keeps an emergency role, `ferro-breakglass-admin`, that trusts the
  whole account; the auditor must never be able to reach it.
- ferro-ledger-reader is read-only and only for the 2026 prefix.

## What the auditors report
"AccessDenied when assuming the bridge role." Ferro's cloud team also admits the
chain was rebuilt from an older design after the bridge role was renamed
(it used to be called ferro-audit-bridge-v1).

## Evidence you can collect
The Q3 file is `2026/q3.csv`; once the chain works, reading it proves the path.
