# Solution

1. **Bucket policy.** `QuickShareForPartner` allows `s3:GetObject` on the whole bucket to `Principal: "*"`. Download the policy, remove only that statement, and put it back. `AnalystsReadPii` stays, so analysts keep working. Deleting the entire policy would break them.
2. **Staff group.** `staff-reading` allows `GetObject` on `ardent-customer-exports/*`. Scope it to `ardent-customer-exports/reports/*`.
3. **Partner users.** `partner-feed` allows `partners/*`. Give each partner only their own prefix (`partners/nova/*`, `partners/zephyr/*`).

`ardent-marketing-assets` is public by design and is left alone.

`check` reads real objects as each identity: it first confirms the legitimate readers still work (analyst, each partner's own feed, staff reports, public logo), then proves that an unrelated identity, the temp contractor and a partner cannot read what they shouldn't.
