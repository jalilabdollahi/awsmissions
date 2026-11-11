# Solution

1. **Dead-letter target.** The redrive policy names `pw-sort-dlq`, which does not exist; the queue is `pw-sort-jobs-dlq`. A redrive policy that points nowhere is accepted silently and simply never parks anything.
2. **Receive limit.** `maxReceiveCount` is 100. Set it to a small number (3 as agreed; anything up to 5 passes).
3. **Visibility timeout.** 2 seconds, but a worker needs up to 30. Raise `VisibilityTimeout` to at least 30.
4. **Alarm.** Create an alarm on `AWS/SQS` `ApproximateNumberOfMessagesVisible` with dimension `QueueName=pw-sort-jobs-dlq`, threshold 0 with `GreaterThanThreshold`, and the action `arn:aws:sns:us-east-1:000000000000:pw-ops-alerts`.

Items 1 to 3 are a single `aws sqs set-queue-attributes` call with a JSON file (the RedrivePolicy is a JSON string inside the JSON map).

`check` copies the queue's redrive settings onto a scratch queue, sends a poison message and receives it repeatedly without deleting it (like a crashing worker). The message must show up in the real DLQ, and the alarm must then page `pw-ops-pager`.
