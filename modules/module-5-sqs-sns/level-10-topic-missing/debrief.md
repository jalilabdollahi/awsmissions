# Debrief: a topic has no memory of who listened

An SNS topic is just a named fan-out point. Its subscriptions are child objects: delete the topic and every subscription goes with it, even though the queues and Lambda functions on the other side are untouched. `CreateTopic` is idempotent and returns the same ARN for the same name, so recreating the topic restores the *address* but none of the *wiring*.

**What a publish to a missing topic looks like.** `Publish` fails with `NotFound`. Producers that swallow that error (a fire-and-forget logger, for example) make the outage invisible until a downstream team notices missing data.

**In real life**
- Define topic, subscriptions and queue policies in the same infrastructure stack so they are created and rolled back together.
- Mark production topics with a stack policy or deletion protection in your IaC tooling; a rolled-back stack deletes topics it created.
- Keep a list of subscribers outside the topic (in code), or use `aws sns list-subscriptions-by-topic` before any destructive change.
- Alarm on the publisher's error rate, not only on the consumer's queue depth: an empty queue looks healthy.
