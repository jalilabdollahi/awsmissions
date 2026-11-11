# INC-6611 - Case documents and the case index wiped by an intern's clean-up script

Marlow & Quayle Legal. Friday 17:10: associates report that every case folder
is empty and the case search returns nothing.

## What happened (reconstructed)
- An intern (`ml-intern`) was asked to "tidy the scratch area" and ran a
  recursive delete against the wrong bucket (`ml-case-documents`) and a
  clean-up loop against the case index table (`ml-case-index`).
- Before that, a bad sync tool had overwritten one contract
  (`contracts/acme-msa.txt`) with a corrupted, near-empty version.
- A "storage optimisation" job then switched versioning on the document
  bucket from Enabled to Suspended.

## What exists
- Bucket `ml-case-documents`: versioning was Enabled for years. Documents:
  `contracts/acme-msa.txt`, `contracts/brightwater-nda.txt`, `pleadings/calder-v-dunmore.txt`.
- DynamoDB `ml-case-index` (key `caseId`) with Point-in-Time Recovery enabled:
  four cases C-101 to C-104, each with a `client` attribute.
- The last moment both stores were still healthy is recorded in SSM parameter
  `/marlow/incident/last-good-time` (UTC, ISO 8601).

## Rules
- Recover every document with its correct content and every case row, without
  losing history.
- Restoring a table is a *copy*: PITR restore always writes a NEW table; the live
  table name `ml-case-index` has to end up holding the cases again.
- Make a repeat impossible: the intern still needs to read and add documents
  and cases (casework continues), but must not be able to delete anything.
- Versioning is part of the safety net: put it back.
