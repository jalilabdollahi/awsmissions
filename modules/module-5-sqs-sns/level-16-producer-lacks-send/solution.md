# Solution

The policy has two independent mistakes. Either one alone would cause `AccessDenied`:

- The action is `sqs:SendMessages`. No such action exists (the real one is `sqs:SendMessage`), so the statement never matches a request.
- The resource is the ARN of `gatehouse-audit`, the queue the API must *not* write to.

```bash
aws iam get-user-policy --user-name gatehouse-api --policy-name intake-writer
```

Fix `policy.json`:

```json
{
  "Effect": "Allow",
  "Action": ["sqs:SendMessage", "sqs:GetQueueUrl"],
  "Resource": "arn:aws:sqs:us-east-1:000000000000:gatehouse-intake"
}
```

Apply it:

```bash
aws iam put-user-policy --user-name gatehouse-api --policy-name intake-writer \
  --policy-document file://policy.json
```

Run `check`. The validator sends a message as the user, then makes sure the user still cannot write to the audit queue, read from intake, or purge it.
