# Debrief: backups are per table, and scope is a policy question

Point-in-time recovery (PITR) continuously backs up a table so you can restore it to any second in the last 1 to 35 days (the default is 35). It is **off by default**, and it is a per-table switch (`update-continuous-backups`). Nothing about a table's name, environment or importance turns it on for you. Restores always create a **new table**; they never overwrite the original. Plan time for it: index, TTL, streams, tags, autoscaling and IAM are not all carried over automatically.

What happened at Ledgerly is the classic compliance gap: protecting the table everyone remembers and missing the ones nobody listed. Define scope with data you can query:
- Tag resources (`compliance=sox`, `data-class=financial`) at creation time through IaC.
- Audit with the tag-based APIs (`list-tags-of-resource`, the Resource Groups Tagging API, or AWS Config rules such as `dynamodb-pitr-enabled`).
- Enforce with a Service Control Policy or Config remediation so nobody can create a tagged table without PITR.

Cost awareness matters too: PITR is billed per GB-month of table size. Scratch and cache tables are normally not worth it, which is why the scratch table stays out.

Other notes:
- PITR protects against accidental writes/deletes by people and code. It does not protect against someone deleting the table with `DeleteTable` unless you also use deletion protection (and take on-demand backups to a second account for ransomware-style scenarios).
- The earliest restorable time is the moment PITR was enabled. Enabling it *after* the incident cannot rescue data. That is the strongest argument for doing it on day one.
