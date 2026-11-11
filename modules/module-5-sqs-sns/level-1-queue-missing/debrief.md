# Debrief: names are addresses

An SQS queue is identified by its name inside an account and region. `GetQueueUrl("harborline-orders")` either returns a URL or fails with `NonExistentQueue`; there is no fuzzy matching and no auto-create on first send. A one-character typo in infrastructure code produces a perfectly valid queue that nobody uses, which is why this failure is so easy to miss: `list-queues` looks healthy.

**Long polling.** With `ReceiveMessageWaitTimeSeconds=0` (short polling) every empty `ReceiveMessage` call returns immediately, costs a request, and may even miss messages stored on a subset of servers. Setting the wait to 10 to 20 seconds on the queue makes the call block until a message arrives, which cuts empty receives, lowers cost and reduces latency. Consumers can still override it per call.

**In real life**
- Create queues in infrastructure as code (CloudFormation, Terraform, CDK) and pass the name or URL to applications through one shared output, not by retyping it.
- Alarm on `NumberOfEmptyReceives` to find consumers that still short-poll.
- Queue names allow only letters, digits, hyphens and underscores, up to 80 characters; FIFO queues must end in `.fifo`.
