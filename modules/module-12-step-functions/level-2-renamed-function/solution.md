# Solution

The `CheckEligibility` Task points at `function:check-refill-eligibility`, a name that no longer exists. Executions fail with `Lambda.ResourceNotFoundException` before any code runs.

1. Read the failure and list the real function names:

```bash
aws stepfunctions get-execution-history --execution-arn <executionArn>
aws lambda list-functions --query 'Functions[].FunctionName'
```

2. Two functions look right: `refill-eligibility-check` and `refill-eligibility-check-staging`. Production is the one without a suffix. Change the `Resource` in `refill-flow.asl.json` (`edit`):

```json
"Resource": "arn:aws:lambda:us-east-1:000000000000:function:refill-eligibility-check"
```

3. Push the new definition:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:harborview-refill-flow \
  --definition file://refill-flow.asl.json
```

The role's wildcard allows both functions, which is why the staging name would also "work". The validator checks the ruleset in the output so only production passes.
