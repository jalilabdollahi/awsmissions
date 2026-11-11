# Solution

The `ByPriority` Choice state has rules for `urgent`, `high` and `normal` only. For any other value no rule matches, and with no `Default` the state has nowhere to go, so the execution fails with `States.Runtime` ("The state does not point to a next state"). The `Backlog` state already exists and is reachable only through the `normal` rule.

1. Look at a failed execution:

```bash
aws stepfunctions list-executions --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:brightwave-ticket-triage --status-filter FAILED
aws stepfunctions describe-execution --execution-arn <executionArn>
```

2. Add a `Default` next to `Choices` in `triage.asl.json` (`edit`):

```json
"ByPriority": {
  "Type": "Choice",
  "Choices": [ ... ],
  "Default": "Backlog"
}
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:brightwave-ticket-triage \
  --definition file://triage.asl.json
```
