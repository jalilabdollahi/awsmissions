# Debrief: two sides of every cross-service delivery

When SNS delivers to an SQS queue, the caller is not your user or role: it is the service principal `sns.amazonaws.com`. An identity policy cannot grant that. The only thing that can is the queue's **resource-based policy**. If it is missing, SNS records a failed delivery (visible in the `NumberOfNotificationsFailed` metric and, if enabled, in delivery-status logs) and the message is lost, unless the subscription has its own dead-letter queue.

**Why the SourceArn condition matters.** Allowing `sns.amazonaws.com` alone means "any SNS topic anywhere". Because the principal is a shared AWS service, an attacker who knows your queue ARN could create a topic in their own account and push messages into your queue. `aws:SourceArn` pins the permission to your topic (the *confused deputy* problem). `aws:SourceAccount` is a coarser alternative.

**In real life**
- The same pattern applies to EventBridge, S3 event notifications, CloudWatch alarms and Lambda destinations writing to SQS or SNS: look at the resource policy of the *target*.
- Policy changes are easy to get wrong silently. Test with a real publish after every change and watch the failure metrics.
- When an SQS queue is encrypted with a customer-managed KMS key, the key policy must also allow the SNS service to use the key.
- Note for this environment: the local emulator delivers SNS messages even without a queue policy, so the validator inspects the policy itself. AWS does not forgive a missing policy.
