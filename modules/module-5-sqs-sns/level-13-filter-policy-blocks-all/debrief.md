# Debrief: where does the filter look?

A filter policy has two halves that must agree: the *rules* (`{"eventType": [...]}`) and the *scope*, which says what the rules are applied to.

- `MessageAttributes` (the default): the rules are matched against the attributes sent with `Publish --message-attributes`. A message without that attribute matches nothing, so a policy with a required key silently drops everything.
- `MessageBody`: the message body must be valid JSON, and the rules are matched against its properties. Nested objects use nested policy objects: `{"detail": {"status": ["failed"]}}`.

**Why it is so hard to spot.** A subscription whose filter matches nothing looks healthy: it is confirmed, the publisher gets no errors, the metric `NumberOfNotificationsFilteredOut` just climbs. Filtered-out messages are not retried and not dead-lettered; they are gone for that subscriber.

**In real life**
- Use `--message-attributes` when you control the publisher: attribute filtering is cheaper and works for non-JSON bodies. Use body filtering for vendor events and for EventBridge-style payloads.
- Alarm on a consumer queue that receives nothing while the topic's `NumberOfMessagesPublished` rises.
- A policy can use prefix, numeric, `anything-but` and `exists` operators; keep them readable and cover them with a publish test.
- When you change the scope, existing policies keep their text but are now matched against a different thing, so retest.
