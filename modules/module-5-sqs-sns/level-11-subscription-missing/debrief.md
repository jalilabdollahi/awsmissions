# Debrief: fan-out is opt-in, per consumer

SNS delivers a copy of each message to every confirmed subscription on the topic. That makes it ideal for fan-out: add a new consumer by adding a subscription, without touching the publisher. The flip side is that a new consumer receives nothing until somebody subscribes it. Messages published *before* the subscription existed are never replayed to it.

**Details that trip people up**
- The subscription endpoint for SQS is the queue **ARN**. The queue URL is a different thing and is rejected or ignored.
- Subscribing an SQS queue in the same account and region is confirmed automatically. Cross-account subscriptions need the queue policy to allow it and may need confirmation.
- Each consumer should have its own queue. Sharing one queue between two services turns fan-out into competition: each message goes to only one of them.

**In real life**
- Keep subscriptions in the consumer's own stack ("I need these events, so I subscribe"), so a new service cannot be forgotten.
- `aws sns list-subscriptions-by-topic` is the first command to run for "my consumer gets nothing".
- Because history is not replayed, a consumer that needs to catch up needs another source (the event store, or a copy retained in an S3 archive).
