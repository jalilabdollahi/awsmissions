# Solution

A Parallel state returns **an array**: one element per branch, in branch order, each holding that branch's final output. The next state expected objects (`$.billing.plan`, `$.usage.gbUsed`) and also the original `$.customerId`, which the default `ResultPath: "$"` throws away.

1. See the real shape in the history (`ParallelStateExited` output):

```bash
aws stepfunctions get-execution-history --execution-arn <executionArn>
```

It looks like `[{"plan": ...}, {"gbUsed": ...}]`.

2. In `profile-card.asl.json` (`edit`), turn the array into named fields with `ResultSelector`, and store it next to the input with `ResultPath`:

```json
"Gather": {
  "Type": "Parallel",
  "Branches": [ ... ],
  "ResultSelector": { "billing.$": "$[0]", "usage.$": "$[1]" },
  "ResultPath": "$.lookups",
  "Next": "PublishCard"
}
```

and update the paths in `PublishCard`:

```json
"plan.$": "$.lookups.billing.plan",
"gbUsed.$": "$.lookups.usage.gbUsed"
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:orbit-profile-card \
  --definition file://profile-card.asl.json
```
