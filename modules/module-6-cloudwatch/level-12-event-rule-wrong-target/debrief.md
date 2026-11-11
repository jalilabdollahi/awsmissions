# Debrief: a rule is a pattern plus a list of targets

A rule answers two questions: *which events?* (the pattern) and *where do they go?* (up to five targets per rule, each with an `Id` that is unique within the rule). Each matched event is delivered to every target independently. If a target is wrong, EventBridge does not know: delivery to a perfectly valid queue is a success.

**Changing a target**
- `put-targets` with the same `Id` updates that target; with a new `Id` it *adds* one. Adding a prod target while leaving the staging one in place gives you two destinations.
- `remove-targets` takes the target ids, not ARNs. `list-targets-by-rule` shows both.

**Why a wrong target is serious.** Staging systems often have weaker access control and relaxed retention, so real bookings, customer data or payments leak into them without anyone noticing.

**In real life**
- Keep production and staging in different accounts so the wrong ARN cannot be reached at all.
- Set a **dead-letter queue** and a **retry policy** on targets: failed deliveries (for example to a queue whose policy denies EventBridge) are then kept instead of dropped.
- For SQS targets the queue policy must allow `events.amazonaws.com` to `sqs:SendMessage`, usually conditioned on the rule's ARN.
- Review `list-targets-by-rule` output in code review of any event-routing change.
