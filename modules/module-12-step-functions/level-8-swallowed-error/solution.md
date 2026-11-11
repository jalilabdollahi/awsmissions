# Solution

The `Catch` on `ChargeCard` does catch the error, but routes it straight to a `Succeed` state. An error was handled by declaring victory.

1. Prove it with a declined order:

```bash
aws stepfunctions get-execution-history --execution-arn <executionArn>
```

You will see `LambdaFunctionFailed` (error `CardDeclined`) followed by `ExecutionSucceeded`.

2. Rewire the catch in `checkout.asl.json` (`edit`): keep the error with `ResultPath`, notify the customer, then fail.

```json
"Catch": [
  { "ErrorEquals": ["States.ALL"], "ResultPath": "$.error", "Next": "NotifyDeclined" }
],
...
"NotifyDeclined": {
  "Type": "Task",
  "Resource": "arn:aws:states:::sqs:sendMessage",
  "Parameters": {
    "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/pinecrest-declined",
    "MessageBody.$": "States.JsonToString($)"
  },
  "Next": "PaymentFailed"
},
"PaymentFailed": {
  "Type": "Fail",
  "Error": "PaymentFailed",
  "Cause": "The charge was not completed; the customer has been notified."
}
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:pinecrest-checkout \
  --definition file://checkout.asl.json
```

`ResultPath: "$.error"` keeps the order fields and adds `{"Error": "CardDeclined", "Cause": "..."}`, so the message carries both the orderId and the reason.
