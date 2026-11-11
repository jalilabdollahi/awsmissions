# Debrief: logging on Fargate

On EC2 you can pick any Docker logging driver supported by the host. On Fargate you cannot touch the host, so AWS only offers drivers it operates: `awslogs` (CloudWatch Logs), `splunk` and `awsfirelens` (FireLens/Fluent Bit routing to many destinations). A task definition with another driver may register without complaint and then simply fail to deliver logs, which is the quietest kind of outage.

For `awslogs` the essential options are:
- `awslogs-group`: where lines go. Unless you set `awslogs-create-group: "true"` (needs `logs:CreateLogGroup` on the execution role) the group must exist, and it keeps its own retention and metric filters.
- `awslogs-region`
- `awslogs-stream-prefix`: required on Fargate; streams are named `prefix/container/task-id`.

Real-world tips:
- Set a retention policy on every group; the default is "never expire", which silently grows the bill.
- The execution role needs `logs:CreateLogStream` and `logs:PutLogEvents` (the managed `AmazonECSTaskExecutionRolePolicy` has them).
- Dashboards and alarms keyed to a log group name break when the name changes, so configure the group in IaC and reference it from the task definition.
