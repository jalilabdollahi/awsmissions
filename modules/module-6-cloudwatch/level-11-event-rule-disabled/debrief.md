# Debrief: rules have an on/off switch

Every EventBridge rule is `ENABLED` or `DISABLED`. A disabled rule keeps its pattern and its targets, shows up normally in `list-rules` and the console, and simply never matches. There is no error, no dead-letter entry and no failed invocation, because as far as EventBridge is concerned nothing was supposed to happen.

**How to debug "events do not arrive"** (in this order):
1. Is the **rule enabled** (`describe-rule`)?
2. Does the **pattern match** the actual event (`test-event-pattern` with a real event, see the next levels)?
3. Is the **target** the right one, and does the target's own policy allow EventBridge to deliver (an SQS queue policy for `events.amazonaws.com`, a Lambda resource policy)?
4. Check the rule's metrics: `TriggeredRules`, `Invocations`, `FailedInvocations`, `MatchedEvents`.

**Why rules get disabled.** People disable rules to stop an incident or during a migration, and forget. Infrastructure code that sets `State: DISABLED` for a "staging" copy sometimes leaks into production.

**In real life**
- Alarm on `MatchedEvents` dropping to zero for rules that should always see traffic.
- Prefer scheduled, code-reviewed state changes to manual ones, and tag rules you disable on purpose with a reason and a date.
- A disabled rule does not replay: events published while it was off are gone, unless you use an event archive and replay.
