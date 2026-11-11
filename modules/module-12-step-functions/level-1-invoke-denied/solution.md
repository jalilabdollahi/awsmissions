# Solution

The state machine's definition is fine. A Task state that calls a Lambda function does so *as the execution role*, and `tidewater-label-flow-role` only allows X-Ray calls, so the invoke is refused.

1. Find the real error in the execution history:

```bash
aws stepfunctions list-executions --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:tidewater-label-flow
aws stepfunctions get-execution-history --execution-arn <executionArn>
```

The `LambdaFunctionFailed` event says `Lambda.AccessDeniedException ... not authorized to perform: lambda:InvokeFunction`.

2. Add a statement for that one function to `role-policy.json` (`edit`):

```json
{
  "Sid": "InvokeLabelPrinter",
  "Effect": "Allow",
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:us-east-1:000000000000:function:print-shipping-label"
}
```

3. Replace the inline policy and check:

```bash
aws iam put-role-policy --role-name tidewater-label-flow-role --policy-name flow-permissions --policy-document file://role-policy.json
```

Do not use `"Resource": "*"`. The validator proves the role still cannot invoke `print-customs-form`.
