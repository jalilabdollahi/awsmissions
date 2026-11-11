# Debrief: when the message is bigger than the envelope

An SQS message can hold at most 1 MiB (it was 256 KiB until 2025; many libraries and older queues still use the smaller limit, and `MaximumMessageSize` can lower it per queue). Anything larger fails at `SendMessage` and no retry can help. SNS has the same kind of limit for its messages.

**The claim-check pattern** keeps the queue for what it is good at, small, ordered, durable notifications, and puts the bulk elsewhere:

1. The producer writes the payload to S3 (with a unique key, ideally with the encryption and lifecycle rules you need).
2. It sends a tiny message with the bucket, key (and optionally the version id and checksum).
3. The consumer fetches the object, processes it, deletes the queue message and, when appropriate, the object.

AWS ships this as the *Amazon SQS Extended Client Library* (Java) and the *Python* equivalent, which use a reserved message format (`software.amazon.payloadoffloading.PayloadS3Pointer`).

**In real life**
- Give the consumer role read access to the offload bucket and the producer write access; the queue policy alone does not grant S3 access.
- Add an S3 lifecycle rule so abandoned payloads expire, and keep the retention period of the queue shorter than the object lifetime.
- Include a checksum in the pointer so the consumer can detect a truncated or replaced object.
- Compressing the payload (gzip) is the cheap first step, but it only postpones the problem if the data keeps growing.
