# Debrief: patterns are exact-match filters

An event pattern is a JSON document shaped like the event. Each field lists the acceptable values: all fields must match (AND), any value in a list may match (OR). Rules:

- Matching is **exact and case-sensitive**: `gold` is not `Gold`, `quillshop.order` is not `quillshop.orders`.
- A field you leave out is not checked at all, which is how you widen a pattern.
- Nested fields (`detail.tier`) follow the event's structure. You can also match prefixes (`{"prefix": "quillshop."}`), `anything-but`, `exists`, `numeric` ranges and more in real EventBridge. (The local emulator implements only the basic subset, so numeric operators are not exercised here.)
- A pattern that matches nothing is perfectly valid. EventBridge cannot tell "no events yet" from "pattern is wrong".

**Debugging tools**
- `aws events test-event-pattern` evaluates a pattern against a sample event without sending anything.
- The console's sandbox and the `MatchedEvents` / `TriggeredRules` metrics show whether any event matches at all.
- An event archive and replay lets you re-run recent traffic through a corrected rule.

**In real life**
- Copy the pattern from a real captured event, then delete fields to loosen it, instead of typing from memory.
- Document the event contract (source names, detail-types, enums) in one place; typos like `order` / `orders` are the usual cause of silent rules.
- Alarm if a rule that should see traffic has matched zero events for a while.
