# Solution

Two independent problems keep the alarm silent:

1. `"ActionsEnabled": false`: the alarm still evaluates and changes state, but it never executes its actions.
2. `AlarmActions` points to `halcyon-oncall-legacy`, a topic without subscribers, instead of `halcyon-oncall`.

```bash
aws cloudwatch describe-alarms --alarm-names halcyon-db-connections-high \
  --query 'MetricAlarms[0].[ActionsEnabled,AlarmActions]'
```

Fix `alarm.json` (`ActionsEnabled: true`, and the on-call topic ARN in `AlarmActions`) and apply it:

```bash
aws cloudwatch put-metric-alarm --cli-input-json file://alarm.json
```

(`aws cloudwatch enable-alarm-actions --alarm-names halcyon-db-connections-high` fixes only the first problem.) Run `check`: the validator pushes 480 connections, waits for ALARM and looks for the notification in the pager app's queue.
