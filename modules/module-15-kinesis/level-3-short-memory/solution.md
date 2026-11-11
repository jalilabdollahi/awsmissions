# Solution

A Kinesis stream deletes records older than its **retention period**. New streams default to 24 hours, which is nowhere near a 72-hour outage. The period can be raised to as much as 8760 hours (365 days), and anything above 24 hours is billed extra; up to 168 hours (7 days) is the cheaper "extended" tier, which is the budget finance gave you.

1. See the current value:

```bash
aws kinesis describe-stream-summary --stream-name meter-reads --query StreamDescriptionSummary.RetentionPeriodHours
```

2. Raise it to at least 96 hours (72h outage + 24h margin) and at most 168 hours:

```bash
aws kinesis increase-stream-retention-period --stream-name meter-reads --retention-period-hours 96
```

3. Run `check`. The validator makes sure the original reads are still there (so the stream was not recreated) and that the retention value sits in the allowed window.
