# Solution

The service wants a queue named `harborline-orders`, but the deploy only created `harborline-order`. Queue names are exact: SQS will not guess what you meant.

```bash
aws sqs list-queues
aws sqs create-queue --queue-name harborline-orders \
  --attributes ReceiveMessageWaitTimeSeconds=10
```

`ReceiveMessageWaitTimeSeconds=10` makes long polling the default for every consumer of the queue. You can leave the mis-named queue alone, or delete it once nothing uses it.

Run `check`: the validator sends an order to the queue, receives it back, and confirms the long-polling setting.
