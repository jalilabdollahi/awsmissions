# Debrief: permission names and ARNs are matched literally

IAM does not validate action names against the service when you save a policy. An unknown action such as `sqs:SendMessages` is accepted and simply never matches, which is the same as not granting anything. A wrong resource ARN fails the same way: the policy is valid, it just describes a different queue.

**Least privilege for queues**
- Producers: `sqs:SendMessage` on the queue ARN. (`sqs:GetQueueUrl` is needed if they look the URL up by name.)
- Consumers: `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:ChangeMessageVisibility`, and `sqs:GetQueueAttributes` (Lambda and the SDKs call it).
- Operators only: `sqs:PurgeQueue`, `sqs:SetQueueAttributes`, `sqs:DeleteQueue`.
- A queue's ARN is `arn:aws:sqs:<region>:<account>:<name>`; it is not the queue URL.

**Finding the mistake**
- The IAM policy simulator (`aws iam simulate-principal-policy --action-names sqs:SendMessage --resource-arns <arn>`) shows which statement matched.
- CloudTrail's `AccessDenied` event lists the exact action and resource that was evaluated: compare those two strings with the policy.
- IAM Access Analyzer's policy validation flags unknown actions before you deploy.

**Same-account note.** Within one account, an Allow in either the identity policy or the queue policy is enough; across accounts both must allow it.
