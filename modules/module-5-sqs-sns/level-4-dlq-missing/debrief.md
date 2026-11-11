# Debrief: give failures somewhere to go

Without a dead-letter queue, a message that can never be processed is received, fails, becomes visible again and repeats until its retention period (4 days by default) expires. During that time it burns worker capacity, hides in your metrics as "in flight", and on a FIFO queue it blocks everything behind it in the same message group.

**How redrive works.** SQS counts how many times each message was *received*. When the count would exceed `maxReceiveCount`, SQS moves the message to the dead-letter queue instead of delivering it again. The DLQ is an ordinary queue; the source queue's `RedrivePolicy` is the only thing that connects the two.

**Retention.** The age of a message is its original enqueue time, and it is *not* reset when the message is moved. A DLQ with the same 4-day retention as its source can therefore lose a message almost as soon as it arrives. Give DLQs the maximum 14 days.

**In real life**
- Pick `maxReceiveCount` from your failure model: 3 to 5 for transient errors. Too low parks healthy messages during a short outage; too high delays the alarm.
- Alarm on `ApproximateNumberOfMessagesVisible > 0` for the DLQ. A DLQ nobody watches is just a slower way to lose messages.
- A standard queue needs a standard DLQ and a FIFO queue needs a FIFO DLQ, in the same account and region.
