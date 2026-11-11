# Debrief: a valid address is not the right address

`SendMessage` only needs a queue URL that resolves to a queue the caller may use. Nothing in SQS knows which environment you meant, so a staging URL in a production config produces no error at all, just tickets quietly piling up in the wrong place. The symptom is on the consumer side (an empty queue), not on the producer side.

**Where the URL comes from.** A URL has the form `https://sqs.<region>.amazonaws.com/<account-id>/<queue-name>`. It encodes the account and the name, so a copied URL carries the wrong environment's identity with it. `aws sqs get-queue-url --queue-name X` is the authoritative way to resolve the address; `--queue-owner-aws-account-id` does the same for queues in another account.

**In real life**
- Resolve the URL at start-up from the queue name (`GetQueueUrl`) instead of storing the URL, or export it from the stack that creates the queue so the two can not drift.
- Give each environment its own AWS account if you can: a staging credential then physically cannot write to the production queue.
- Compare `NumberOfMessagesSent` on the producer side with `NumberOfMessagesReceived` on the consumer's queue; a gap is the signature of this bug.
