# Debrief: the callback pattern (.waitForTaskToken)

Adding `.waitForTaskToken` to a service integration changes what "done" means for the Task. Step Functions sends the request, then **pauses the execution** until somebody calls one of:

- `SendTaskSuccess` with the token and an output (becomes the task's result),
- `SendTaskFailure` with the token, an `Error` name and a `Cause` (becomes a failure you can Catch by that name),
- `SendTaskHeartbeat` to show the worker is alive (when `HeartbeatSeconds` is set).

The token is unique per waiting task and is only available through the context object: `"taskToken.$": "$$.Task.Token"`. Whatever system receives the request (a queue consumer, an email link, a chat bot) must carry it back unchanged. A literal `$$.Task.Token` string, as here, is the classic mistake, and it is silent: the message is delivered, the execution waits, nothing ever completes.

Since there is no polling, a waiting task costs nothing, but it needs a **timeout**: `TimeoutSeconds` (here three days) ends an abandoned wait with `States.Timeout`, which you can Catch to escalate or cancel. Without it the task could wait for up to a year.

**Business outcomes versus system failures.** `SendTaskFailure` is how a human "no" enters the workflow. Catch that name, do the follow-up (tell the requester) and decide deliberately how the execution should end. Rejection here is expected, so SUCCEEDED is honest; "payment gateway down" would not be.

**In real life**
- Treat tokens like passwords: they are bearer secrets for exactly one task. Do not log them, do not put them in URLs that outlive the wait.
- The same pattern drives human approval, third-party async APIs, and long-running jobs; `.sync` integrations (ECS, Glue, Batch, nested Step Functions) are the same idea with the token handled by AWS.
- Use `ResultPath` on callback tasks: the callback payload is controlled by someone else and replaces your data by default.
