# Solution

SNS is a separate service principal. To deliver to a queue it needs permission from the queue's **resource policy**. The right policy names the SNS service as principal, `sqs:SendMessage` as action, the queue as resource, and pins the sender to the topic with an `aws:SourceArn` condition. Without the condition, any topic in any account that knows the queue ARN could write to it (a confused-deputy hole).

1. Complete `policy.json` (`edit`): put the queue ARN into `Resource` and add the condition:

```json
{
  "Sid": "AllowSnsDelivery",
  "Effect": "Allow",
  "Principal": { "Service": "sns.amazonaws.com" },
  "Action": "sqs:SendMessage",
  "Resource": "arn:aws:sqs:us-east-1:000000000000:ember-pager-intake",
  "Condition": { "ArnEquals": { "aws:SourceArn": "arn:aws:sns:us-east-1:000000000000:ember-alerts" } }
}
```

2. The `Policy` attribute is a JSON string, so wrap the document and apply it:

```bash
python3 -c 'import json; print(json.dumps({"Policy": open("policy.json").read()}))' > attributes.json
aws sqs set-queue-attributes \
  --queue-url $(aws sqs get-queue-url --queue-name ember-pager-intake --query QueueUrl --output text) \
  --attributes file://attributes.json
```

3. Run `check`: the validator publishes an alert, confirms it arrives, then evaluates the stored policy for the SNS principal.
