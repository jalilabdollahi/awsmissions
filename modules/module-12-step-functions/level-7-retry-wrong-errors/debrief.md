# Debrief: Retry is a list of exceptions, not a general safety net

A Retry block says: "if this state fails with one of these *named* errors, wait and try again". Matching is by error name, evaluated top to bottom, first retrier whose `ErrorEquals` contains the error wins, and each retrier keeps its own attempt counter.

Where do error names come from?
- **Lambda service errors** (`Lambda.ServiceException`, `Lambda.TooManyRequestsException`, ...) come from the platform, not your code. They are the standard transient set and why the AWS docs recommend the list in this definition.
- **Your function's exceptions**: a Python exception class `StockLocked` becomes the error `StockLocked`; in Node, `error.name`. The cause holds the message and stack trace.
- **Built-ins** such as `States.Timeout`, `States.TaskFailed` and the catch-all `States.ALL`.

The timing fields: `IntervalSeconds` is the first wait, `BackoffRate` multiplies it each time (2 means 2 s, 4 s, 8 s), `MaxAttempts` counts retries after the first try (0 disables retry), and `JitterStrategy: "FULL"` randomises waits so many executions do not hammer a recovering service in lockstep.

**Only retry what is transient.** The unknown-SKU error would fail identically every time. A broad `States.ALL` retrier turns a clear, immediate failure into a slow one and multiplies load on a struggling dependency.

**In real life**
- Make the workflow resilient to the failure you can observe, then add `Catch` for what is left (next missions).
- Retries are billed as extra state transitions on Standard workflows and extra duration on Express ones. Cap total wait below your caller's patience.
- Lambda may run a function more than once on retry, so the task must be idempotent (use an idempotency key such as the order line id).
