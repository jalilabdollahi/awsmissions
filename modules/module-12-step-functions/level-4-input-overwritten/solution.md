# Solution

A Task state without `ResultPath` replaces its whole input with the task's result (the default is `ResultPath: "$"`). The Lambda returns only `{"riskScore": ..., "model": ...}`, so by the time `QueueForReview` runs the order is gone.

1. Compare the input and the output of the first state in the history:

```bash
aws stepfunctions get-execution-history --execution-arn <executionArn> --query 'events[?type==`TaskStateEntered` || type==`TaskStateExited`]'
```

2. Tell `ScoreOrder` to *merge* the result into the input instead of replacing it. In `order-screening.asl.json` (`edit`):

```json
"ScoreOrder": {
  "Type": "Task",
  "Resource": "arn:aws:lambda:us-east-1:000000000000:function:lumen-fraud-score",
  "ResultPath": "$.fraud",
  "Next": "QueueForReview"
}
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:lumen-order-screening \
  --definition file://order-screening.asl.json
```

The message now contains the original order plus a `fraud` object. Any key name works, as long as it is not `$` (which means "replace everything").
