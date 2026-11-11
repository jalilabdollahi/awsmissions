# Debrief: retention is the cheapest cost control you have

CloudWatch Logs bills for **ingestion** (once, when events arrive) and for **storage** (every month, for as long as they are kept). New log groups default to *never expire*, so storage cost only ever goes up. A retention policy tells the service to delete events older than N days; deletion runs in the background, typically within about a day of expiry.

**Details**
- Allowed values are a fixed list: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 and 3653 days.
- Changing retention is not retroactive in the sense of "refund": older events are removed, but data already ingested was already paid for.
- Metric filters keep producing metrics even after the underlying events expire; retention affects only the raw events.

**Why the audit group must stay different.** Retention is a compliance decision, not just a cost one. A script that "fixes" every group in the account would silently delete a year of audit evidence after 30 days. Always scope bulk changes by prefix, and review the list first.

**In real life**
- Set retention in the same infrastructure code that creates the log group, and make the application's own "create group" permission unnecessary.
- For long-term archives, export or subscribe the logs to S3 (cheaper) and keep only recent data in CloudWatch.
- Use `aws logs describe-log-groups --query 'logGroups[?retentionInDays==null]'` in a periodic audit to find groups that never expire.
