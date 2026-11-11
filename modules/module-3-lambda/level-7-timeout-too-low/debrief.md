# Debrief: the timeout is a budget, not a guess

`Task timed out after 3.00 seconds` is Lambda killing the invocation when it reaches the configured timeout. The default for new functions is 3 seconds; the maximum is 900 seconds (15 minutes). Nothing about the code is wrong; the environment just refuses to wait.

How to choose a value:
- Measure the slowest realistic request (here 12 pages x 0.6 s = 7.2 s) and add headroom. Cold starts count against the same timeout.
- Work out who is waiting. API Gateway REST APIs hard-stop at 29 s; ALB defaults to 60 s; an SQS-triggered function needs a queue visibility timeout of at least 6x the function timeout. A function timeout longer than the caller's patience just means work continues in the dark after the caller has already given up.
- Do not set 900 "to be safe". A hung downstream call then keeps (and bills) the environment for 15 minutes, and a retry storm becomes expensive.

**Related knobs**: memory also scales CPU, so a CPU-bound function may finish faster with more memory than with a longer timeout (the next missions look at memory). `context.get_remaining_time_in_millis()` lets your code stop cleanly (flush partial results, requeue the rest) before the hard kill.

**In real life**
- Alarm on the `Duration` metric at about 80% of the timeout so you see trouble coming.
- For genuinely long work, split it (Step Functions, SQS fan-out) instead of stretching the timeout.
