# Debrief: catching an error is not the same as handling it

`Catch` intercepts a failure (after any `Retry` is exhausted) and sends the execution to another state instead of failing. Whatever that next state does is the **handler**. Here the handler was a `Succeed`, so the platform's most important signal, execution status, lied.

Two details make Catch useful:

- **The error object.** Caught errors arrive as `{"Error": "...", "Cause": "..."}`. By default (`ResultPath: "$"`) that object *replaces* the input, so the handler loses the order. `ResultPath: "$.error"` keeps both.
- **What the handler ends with.** Compensate, notify, or clean up, then end in a `Fail` state so the status, the `ExecutionsFailed` metric and your alarms still tell the truth. Use `Succeed` only when the business outcome really is a success ("order cancelled by customer" is not a failure; "payment declined, order not placed" arguably is).

Catchers match by name, top to bottom, like Retry. Use specific names for specific business reactions (`CardDeclined` to message the customer) and a final `States.ALL` as the safety net. In the Amazon States Language, `States.ALL` must be the last element of a catcher list.

**In real life**
- Put a CloudWatch alarm on `ExecutionsFailed` and `ExecutionsTimedOut`. If those never fire, ask whether errors are being swallowed.
- Reconciliation data (payments, shipments) should be the source of truth in audits, but a `SUCCEEDED` status that does not mean "business success" makes every dashboard misleading.
- A `Fail` state's `Error` and `Cause` are searchable in the console and in the execution history; choose names that tell on-call what happened.
