# Debrief: replaying a dead-letter queue safely

Parking failed messages is only half of a DLQ strategy; the other half is getting them processed again once the cause is fixed. SQS offers **DLQ redrive** through `StartMessageMoveTask`:

- It moves messages from the DLQ to a destination (by default the queue each message originally came from), in the background, without you writing a consumer.
- Messages are *moved*: the DLQ shrinks as the destination grows, so nothing is processed twice by the replay itself.
- `--max-number-of-messages-per-second` throttles the replay so a recovering consumer is not flooded.
- `list-message-move-tasks` shows progress (`ApproximateNumberOfMessagesMoved`), and `cancel-message-move-task` stops a running one.

**Why not a hand-written loop.** A receive-send-delete script can lose messages (a crash between send and delete creates a duplicate; between delete and send, a loss), drops attributes unless you copy them, and resets the message's original timestamp. The built-in task avoids these.

**In real life**
- Fix the cause *before* redriving. Otherwise the same messages fail again and come straight back.
- Replay slowly at first and watch the consumer's error rate.
- Consumers should be idempotent; a message that was half-processed before it failed may be processed again.
- Redrive works for standard queues; for FIFO queues the DLQ must itself be FIFO.
