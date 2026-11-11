# Debrief: S3 pushes events only where you tell it to

An S3 event notification configuration lives on the bucket and lists *destinations* (SQS queue, SNS topic, Lambda function or EventBridge), the *events* that trigger them, and optional *filters*. With no configuration, S3 says nothing; the downstream queue can be perfectly healthy and still silent.

**Anatomy of a rule**
- `Events`: `s3:ObjectCreated:*` covers Put, Post, Copy and CompleteMultipartUpload. `s3:ObjectRemoved:*` covers deletes.
- `Filter.Key.FilterRules`: `prefix` and `suffix` are both exact string matches on the key. Here both are needed, otherwise cover letters and archived invoices would flood the robot.
- `QueueArn`: S3 validates the destination when you save the configuration. If the queue does not exist (or, on real AWS, its policy does not let `s3.amazonaws.com` send messages), the save fails with `Unable to validate the following destination configurations`.

**First message**: when you save a configuration S3 sends an `s3:TestEvent` to the destination. Consumers must tolerate message bodies that have no `Records`.

**In real life**
- On real AWS the queue needs a resource policy allowing `s3.amazonaws.com` to `sqs:SendMessage` with a `aws:SourceArn` condition for the bucket.
- Events are at-least-once and not ordered. Make consumers idempotent.
- The notification API replaces the whole configuration. Fetch the existing one first when other rules exist.
- Overlapping prefixes for the same event type on one bucket are rejected, so design prefixes per consumer.
