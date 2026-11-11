# Solution

The Wait state uses a hard-coded `"Seconds": 604800` (seven days), so `remindAt` is ignored. A Wait state can take its target time from the input instead of from the definition.

1. Confirm what the running executions are doing:

```bash
aws stepfunctions list-executions --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:halcyon-trial-reminder --status-filter RUNNING
```

2. In `trial-reminder.asl.json` (`edit`) replace `Seconds` with a path to the timestamp:

```json
"WaitForReminderTime": {
  "Type": "Wait",
  "TimestampPath": "$.remindAt",
  "Next": "SendReminder"
}
```

3. Update the state machine:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:halcyon-trial-reminder \
  --definition file://trial-reminder.asl.json
```

Executions already running keep the definition they started with, so the stuck ones stay stuck. New executions pick up the fix.
