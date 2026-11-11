# Debrief: composite alarms are logic over states

A composite alarm does not look at metrics. Its `AlarmRule` is an expression built from `ALARM("name")`, `OK("name")` and `INSUFFICIENT_DATA("name")` terms combined with `AND`, `OR`, `NOT` and parentheses. It is `ALARM` when the expression evaluates true. A typical use is **noise reduction**: many fine-grained alarms feed one composite that pages, and only the composite has an action.

**Reading a rule**
- `ALARM(a) OR ALARM(b)`: page when either is bad.
- `ALARM(a) AND ALARM(b)`: page only when both are bad (use for correlated symptoms).
- `ALARM(a) AND NOT ALARM(maintenance)`: suppress pages during a maintenance window.
- `NOT (ALARM(a) OR ALARM(b))` is true when everything is healthy, a very common mistake when someone converts "alert if bad" into code. Check what the rule says when all children are OK; it must be false.

**Gotchas**
- `put-composite-alarm` replaces the definition, including the actions, so always resend them.
- Child alarms should usually have *no* actions of their own, or you get both a child page and a composite page.
- A composite changes state when a child does, so its reaction time is the children's time plus a short evaluation delay.
- A child that is in `INSUFFICIENT_DATA` is neither ALARM nor OK; write the rule for that case if the data can disappear.

**In real life**
- Test composites by driving the children into ALARM, or with `set-alarm-state` on the children in a test environment, and look at both the state and the notification.
- Keep the rule in code next to the child alarms so they are reviewed together.
