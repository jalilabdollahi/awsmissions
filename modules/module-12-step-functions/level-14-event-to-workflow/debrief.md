# Debrief: debugging a chain, one link at a time

An event-driven workflow is a relay race with four hand-offs, and each can fail silently:

1. **Event to rule.** An event pattern matches field by field, and every listed value must match exactly (arrays mean "any of"). A wrong `detail-type` produces no error at all. The event is accepted by `put-events` and then matched by nothing. Silence is the symptom.
2. **Rule to target.** A rule can have up to five targets; each names an ARN. A target that points at the wrong but valid workflow will happily run it (the retired one here succeeds, which is why dashboards looked fine). A target that points at nothing is dropped without an error on the producer's side.
3. **Target input.** For a Step Functions target the default input is the *whole event envelope*. `InputPath` (`$.detail`) selects part of it; `InputTransformer` can build a custom shape. The workflow's own paths decide which is right.
4. **Role to resources.** EventBridge needs a role allowed to `states:StartExecution`. The workflow then needs its **own** execution role allowed to do what its states do (`lambda:InvokeFunction`, `dynamodb:PutItem`). An ARN typo in that policy shows up only as `Lambda.AccessDeniedException` inside the execution.

**Method.** Do not guess. Send one real event and follow it:
- Did any execution start? (`list-executions`). If not, rule or target.
- Which state machine started, and with which input? (`describe-execution`). Compare it with what the first state reads.
- Where did it fail? (`get-execution-history`).
Then fix exactly the link that is broken, retest, and expect the *next* link to show its own symptom.

**In real life**
- Add a dead-letter queue to the target (`DeadLetterConfig`) and enable EventBridge's `FailedInvocations` alarms so mismatches stop being silent.
- Keep patterns as tight as the business needs (source plus detail-type). Overly loose patterns trigger workflows on events nobody meant, which is as costly as missing ones.
- Retire old workflows completely; a "temporary" legacy copy that accepts anything is a trap for the next incident.
- The event bus delivers at least once. Make the workflow idempotent (the item write here is, because it is keyed by orderId).
