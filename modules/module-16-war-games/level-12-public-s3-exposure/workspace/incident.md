# SEC-INC-0719 - Customer export data reachable by people who should not see it

Ardent Analytics (B2B data vendor). Reported by a bug-bounty researcher at 08:55.

## Researcher's summary
"I could download `pii/customers.csv` from your export bucket without any
credentials, and while testing I noticed other buckets and accounts are far too
generous as well."

## Inventory
Bucket `ardent-customer-exports`
- `pii/customers.csv`          sensitive: analysts only
- `reports/q3-summary.pdf`     internal: all staff
- `partners/nova/feed.csv`     partner Nova's own feed
- `partners/zephyr/feed.csv`   partner Zephyr's own feed

Bucket `ardent-marketing-assets`
- `logo.png`  intentionally public; it is on our website.

Identities
- `ardent-analyst`: reads pii through an explicit grant in the bucket policy.
- group `ardent-staff` (includes the temp contractor `ardent-temp-contractor`):
  should read `reports/` only.
- `ardent-partner-nova`, `ardent-partner-zephyr`: each should read only their
  own `partners/<name>/` feed.
- `ardent-outsider` stands in for "anyone else", an authenticated
  user from another team or account with no permissions of its own.

## History
- Two weeks ago, to "quickly share a file with a partner", someone added a
  broad statement to the export bucket policy and never removed it.
- The partner policy was written as `partners/*` "to save time".
- The staff group got the whole bucket "just for the quarter-end".

## Rules
- Fix the exposure; do not take the business down: the analyst grant, partner
  feeds, staff reports and the public logo must keep working.
- Deleting the whole bucket policy is not a fix.
