# Debrief: envelope or payload?

SNS was built for HTTP endpoints and e-mail, where a self-describing envelope makes sense (message id, topic ARN, signature, an unsubscribe URL). For SQS and Lambda targets most consumers just want the payload. `RawMessageDelivery=true` delivers the published message body as-is and, for SQS, copies the publisher's message attributes onto the SQS message as real message attributes.

**What changes for a consumer**
- Without raw delivery: `json.loads(body)["Message"]` is a *string* that you must parse a second time. Message attributes sit inside the envelope under `MessageAttributes`.
- With raw delivery: `json.loads(body)` is your event. Attributes are SQS message attributes (request them with `MessageAttributeNames` on receive).

**Switching it on is not retroactive.** Messages already in the queue keep their envelope, so a consumer should either tolerate both forms during the switch or the queue should be drained first.

**In real life**
- Prefer raw delivery for SQS and Lambda unless you need the envelope's fields.
- Changing attributes of an existing subscription keeps its filter policy, DLQ and ARN; deleting and recreating the subscription loses all three, which would silently change who receives what.
- For FIFO topics, raw delivery is also what lets the queue see the original message group.
