# Debrief: group, stream, event

- A **log group** is the unit of configuration: retention, encryption (KMS), metric filters, subscription filters and access control are all set per group.
- A **log stream** is an ordered sequence of events from one source: a container, a Lambda execution environment, an instance. Streams are cheap and are usually created by the agent or driver.
- A **log event** is a timestamp plus a message.

`PutLogEvents` needs the group *and* the stream to exist. Many agents create both automatically (the CloudWatch agent, Lambda); the Docker `awslogs` driver creates groups only when `awslogs-create-group=true`, and some teams turn that off on purpose so that a typo in a name does not silently create a new group with infinite retention.

**In real life**
- Create log groups in your infrastructure code, with retention set from day one (the default is to keep logs forever and be billed for them).
- Name groups with a stable hierarchy (`/team/service/environment`) so IAM policies and metric filters can use prefixes.
- `ResourceNotFoundException` from the log driver usually means "wrong group name or wrong region", so check both.
