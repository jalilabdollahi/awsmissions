# Solution

Three defects, each hiding the next.

**1. The token is not a token.** The request body contains `"taskToken": "$$.Task.Token"`. Without the `.$` suffix on the key, that is the literal text `$$.Task.Token`. A callback needs the real token that Step Functions generated for this one waiting task, which comes from the context object. Fix the key:

```json
"taskToken.$": "$$.Task.Token"
```

You can see the problem with `aws sqs receive-message --queue-url <brightline-approvals url>`.

**2. The callback result replaces the input.** After a manager calls `send-task-success`, the task's result is whatever they sent (here `{"approvedBy": ...}`). Without a `ResultPath`, the next state receives only that, and `IssuePurchaseOrder` cannot find `$.poId`. Add `"ResultPath": "$.approval"` to `AskManager`.

**3. Rejection is unhandled.** `send-task-failure --error Rejected --cause "over budget"` fails the task with error name `Rejected`. Add a Catch that stores the error and routes to a state that notifies the requester:

```json
"Catch": [
  { "ErrorEquals": ["Rejected"], "ResultPath": "$.rejection", "Next": "TellRequester" }
]
...
"TellRequester": {
  "Type": "Task",
  "Resource": "arn:aws:states:::sqs:sendMessage",
  "Parameters": {
    "QueueUrl": "https://sqs.us-east-1.amazonaws.com/000000000000/brightline-requester-notices",
    "MessageBody": {
      "poId.$": "$.poId",
      "requester.$": "$.requester",
      "outcome": "REJECTED",
      "reason.$": "$.rejection.Cause"
    }
  },
  "End": true
}
```

Update the state machine with `aws stepfunctions update-state-machine --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:brightline-po-approval --definition file://po-approval.asl.json`.
