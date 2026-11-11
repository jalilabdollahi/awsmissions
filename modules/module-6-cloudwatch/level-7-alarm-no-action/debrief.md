# Debrief: three things must line up before a human is paged

For an alarm to wake someone, all of these must be true:

1. The alarm **evaluates** correctly and reaches `ALARM` (the previous levels).
2. **Actions are enabled** (`ActionsEnabled`). Disabling actions is the standard way to silence an alarm during maintenance (`disable-alarm-actions`), and the standard way to forget to turn it back on.
3. The **action target** is something that reaches a person: an SNS topic that has working subscriptions (e-mail, SMS, a pager integration, a queue behind a Lambda).

A topic with zero subscribers accepts publishes happily, so the alarm shows "action executed" in its history and nothing is delivered. Look at `describe-alarm-history` for `Action` entries and at `list-subscriptions-by-topic` for the target.

**Actions run on state transitions.** The ALARM action runs once when the state changes to ALARM, not every period. If you fix the wiring while the alarm is already in ALARM you will not be notified until it recovers and fires again, so test with a fresh breach, as the validator does.

**In real life**
- Prefer scheduled alarm suppression (composite alarms with a maintenance alarm, or EventBridge scheduled disable/enable) to manual muting.
- Put a "can you hear me?" test in the on-call handover: `aws cloudwatch set-alarm-state --state-value ALARM` on a test alarm exercises the whole path.
- Retire topics deliberately: before deleting or abandoning one, list which alarms still publish to it.
