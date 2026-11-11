# Debrief: tuning maxReceiveCount

The redrive policy turns "a message was received N times" into "this message is a problem". The right N separates two kinds of failure:

- **Transient** (provider timeout, throttling, a deploy in progress): the next attempt usually works. You want several attempts.
- **Permanent** (malformed payload, a bug): no number of retries will help. You want the message parked quickly so it stops wasting capacity.

`maxReceiveCount=1` treats every failure as permanent. A very large value treats every failure as transient and delays the alarm and the parking. For most workloads 3 to 5 is a good start; SQS itself accepts 1 to 1000.

**Remember that "received" is not "failed".** Every receive counts, including ones caused by a visibility timeout that is too short, by a consumer that scales down mid-batch, or by Lambda event-source polling. Lambda's SQS integration also needs a `maxReceiveCount` of at least 5 on the source queue to cope with throttling.

**In real life**
- Combine the count with backoff: extend the visibility timeout on each failure (`ChangeMessageVisibility`) so retries are spaced out and do not hammer a struggling provider.
- When the provider recovers, replay the DLQ with `StartMessageMoveTask` rather than copying messages by hand.
