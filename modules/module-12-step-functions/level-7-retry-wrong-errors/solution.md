# Solution

`Retry` only applies to the error names listed in `ErrorEquals`. The block copied from the documentation lists the three Lambda *service* errors, but the function raises a custom exception, `StockLocked`, whose name becomes the error name. It matches nothing, so the first failure ends the execution.

1. See the real error name of a failed run:

```bash
aws stepfunctions get-execution-history --execution-arn <executionArn> \
  --query 'events[?type==`LambdaFunctionFailed`].lambdaFunctionFailedEventDetails'
```

The `error` field says `StockLocked`.

2. Add a retrier for exactly that error in `reserve.asl.json` (`edit`):

```json
"Retry": [
  {
    "ErrorEquals": ["StockLocked"],
    "IntervalSeconds": 2,
    "MaxAttempts": 4,
    "BackoffRate": 1.5
  },
  { ...the existing Lambda service errors retrier... }
]
```

Do not use `States.ALL` or `States.TaskFailed`: they would also retry `UnknownSku`, which can never succeed.

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:fernhill-reserve \
  --definition file://reserve.asl.json
```

With 2 s, then 3 s, then 4.5 s between attempts, the retries span about 10 seconds, enough for a 5 second lock.
