# Debrief: a Choice state needs a way out

A Choice state evaluates its rules **in order** and takes the first one that matches. If none matches it uses `Default`. If there is no `Default` either, the execution does not quietly end: it fails with `States.Runtime`.

Brightwave's author tested the two cases that mattered that afternoon (urgent, high) and never thought about "everything else". That is the classic Choice bug: the happy paths are covered, the world is bigger than your test data.

**Things to remember**
- Rules are top-to-bottom, first match wins. Put the most specific rule first.
- Always add `Default`, even if it only goes to a `Fail` state with a clear `Error` and `Cause`. A loud, named failure beats a silent route; a missing Default gives you neither.
- A catch-all route to a human-visible queue (like `bw-backlog`) is the right choice for business data that can gain new values later.
- Terminal states are not interchangeable: a Choice cannot be the last state, it is a router. Every path must reach a Task/Pass with `End: true`, a `Succeed` or a `Fail`.

**In real life** CloudWatch alarms on `ExecutionsFailed` catch this class of bug the first morning. Pair them with Default branches that emit a metric, so you learn about unexpected values before customers do.
