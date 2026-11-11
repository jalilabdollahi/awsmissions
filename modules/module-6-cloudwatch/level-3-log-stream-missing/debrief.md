# Debrief: streams are where the writes land

Every call to `PutLogEvents` names a group *and* a stream. If either does not exist the call fails with `ResourceNotFoundException`, and an agent that only logs the failure to its own console makes the problem invisible to the people who read CloudWatch.

**How streams are normally created**
- The CloudWatch agent, the `awslogs` Docker driver (with the right options), Lambda and ECS/EKS log routers create streams automatically.
- Hand-written shippers must call `CreateLogStream` first, ideally once at start-up, and tolerate `ResourceAlreadyExistsException`.
- If an agent is deliberately denied `logs:CreateLogStream`, whoever onboards a new device has to create its stream as a deployment step.

**Properties worth knowing**
- Events within a stream must be in chronological order per batch; a batch can span at most 24 hours and hold 10,000 events or 1 MiB.
- Streams have no configuration of their own: retention and filters belong to the group.
- Many streams in one group is normal. Insights queries and `filter-log-events` search across all of them.

**In real life**
- Name streams after a stable identity (gateway id, pod name) so a stream maps to one source.
- Give agents `logs:CreateLogStream` and `logs:PutLogEvents` on their own group, nothing more. If you remove stream creation, make provisioning do it.
- Alarm on a log group that suddenly receives nothing, with a metric filter or the `IncomingLogEvents` metric, so a mute device is noticed within minutes.
