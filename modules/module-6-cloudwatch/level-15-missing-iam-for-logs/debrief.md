# Debrief: a log shipper needs exactly two permissions

For an agent that writes logs, the minimal set is:

- `logs:CreateLogStream`: create its own stream (not needed if provisioning does it).
- `logs:PutLogEvents`: upload batches of events.
- Often also `logs:DescribeLogStreams` (to resume sequence handling in older agents) and, only if the agent should create the group, `logs:CreateLogGroup`.

Everything else, `DeleteLogGroup`, `PutRetentionPolicy`, `PutResourcePolicy`, `DeleteLogStream`, belongs to operators. A compromised or buggy agent with `logs:*` could erase the audit trail it was only supposed to write.

**Scoping in a real account.** Resources for Logs permissions are ARNs of the form `arn:aws:logs:<region>:<account>:log-group:<name>:*` (for `PutLogEvents` and `CreateLogStream`, the `:*` suffix covers the streams). Scope the Allow to the group, or a prefix like `log-group:/lumen/*:*`. This lab's emulator evaluates logs permissions against `*` only, so it can not check the scoping, but you should always do it.

**Clues from the error.** The AccessDenied message names the *action* that was refused. The agent here got past `CreateLogStream` and failed on `PutLogEvents`: the first call that succeeds tells you the policy was attached correctly and only an action is missing.

**In real life**
- AWS-managed policies such as `CloudWatchAgentServerPolicy` bundle the common agent permissions; they are broader than a single-group policy, so review them first.
- IAM Access Analyzer can generate a least-privilege policy from CloudTrail activity after a trial run.
- Remember that log group KMS keys add one more permission check (`kms:GenerateDataKey` / `kms:Decrypt`) if the group is encrypted.
