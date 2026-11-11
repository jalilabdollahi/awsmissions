# Debrief: four ways to wait

A Wait state pauses an execution without running any code and without consuming Lambda time. Exactly one of these fields is allowed:

| Field | Meaning |
|---|---|
| `Seconds` | wait this many seconds, fixed in the definition |
| `SecondsPath` | wait the number of seconds found in the input |
| `Timestamp` | wait until this absolute time, fixed in the definition |
| `TimestampPath` | wait until the absolute time found in the input |

Halcyon needed the last one. The reminder moment depends on the customer, so it has to come from data, not from the definition. Timestamps must be RFC 3339 / ISO 8601 and are most reliably written in UTC with a trailing `Z`; a string such as `2026-03-14 09:30:00` makes the execution fail with `States.Runtime: Invalid Timestamp`. A timestamp that is already in the past simply lets the execution continue.

**One definition per execution.** An execution runs with the definition it started with. Updating the state machine affects only executions started afterwards, so already-waiting ones must be stopped (`stop-execution`) and restarted if they matter.

**In real life**
- A Standard workflow can run for up to one year, which makes Wait a good fit for "do this in 30 days". You pay per state transition, not for the time spent waiting, so a Wait is far cheaper than a Lambda that sleeps.
- Express workflows are limited to five minutes, so a long Wait only works on Standard.
- Executions waiting for days are expected; executions "running for days" that were meant to be quick are a bug signal. Compare `startDate` with the time the business expects.
- `execution history` has no log of a Wait ending early or late, so assert the real timing from `stopDate` when you test.
