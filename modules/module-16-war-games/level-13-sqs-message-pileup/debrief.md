# Debrief: the queue that ate Black Friday prep

## Root causes
1. **Dead-letter target typo.** SQS does not verify that the DLQ in a redrive policy exists in every path, so the poison message was never moved; it recycled forever.
2. **`maxReceiveCount` of 100.** Even with a correct DLQ, a bad message would have been retried a hundred times first, each retry a chance to hammer a downstream system.
3. **Visibility timeout shorter than the work.** With a 2 second timeout and 30 second parcels, messages become visible again while the first worker is still busy, so healthy parcels are processed twice.
4. **No alarm on the DLQ.** A DLQ with no alarm is just a quieter place to lose data.

## Timeline
- Thursday: queue created from a load-test template.
- Thursday 14:00: malformed parcel enters the queue.
- Thursday 14:00 to 20:00: retry storm; sort statistics degrade, no page.
- Thursday 20:10: the hub supervisor phones the ops desk.

## How SQS redrive works
Each time a message is received, its receive count goes up. When the count exceeds `maxReceiveCount`, SQS moves the message to the DLQ named in the redrive policy. The visibility timeout controls how long a received message stays hidden while a consumer works on it; if the consumer does not delete it in time, it reappears and its receive count increments. Short timeouts therefore also push healthy messages toward the DLQ.

## Lessons
- Alarm on `ApproximateNumberOfMessagesVisible > 0` for every DLQ, and wire the alarm to a real pager.
- Set the visibility timeout to a multiple of the longest legitimate processing time (AWS suggests 6x the Lambda timeout for Lambda consumers).
- Keep `maxReceiveCount` between 3 and 5 for most workloads. Make consumers idempotent for the retries you accept.
- Test the failure path on purpose: send one poison message through staging and watch the page arrive.
