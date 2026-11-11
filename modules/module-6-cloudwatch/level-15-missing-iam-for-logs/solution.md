# Solution

Creating a stream and writing events are two different API actions with two different permissions. The policy grants `logs:CreateLogStream` (so the agent can create its stream) and `logs:DescribeLogStreams`, but not `logs:PutLogEvents`, the action that uploads events.

```bash
aws iam get-user-policy --user-name lumen-shipper --policy-name lumen-shipper-logs
```

Add the missing action to `policy.json`, keeping the list short:

```json
"Action": ["logs:CreateLogStream", "logs:DescribeLogStreams", "logs:PutLogEvents"]
```

Replace the inline policy:

```bash
aws iam put-user-policy --user-name lumen-shipper --policy-name lumen-shipper-logs \
  --policy-document file://policy.json
```

Run `check`. As lumen-shipper the validator creates a stream, uploads an event, and confirms the user still cannot delete the group or change its retention.
