# Solution

A standard queue gives best-effort ordering and at-least-once delivery. Strict ordering needs a **FIFO** queue, and a queue's type is fixed when it is created, so you cannot convert `ironwood-ledger-events`.

```bash
aws sqs create-queue --queue-name ironwood-ledger-events.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true
```

Two details matter: the name must end in `.fifo`, **and** `FifoQueue=true` must be set (the suffix alone is not enough in AWS). Producers then send with a `MessageGroupId` (here: the account number); messages inside one group are delivered strictly in order, while different groups are processed in parallel.

Run `check`: the validator sends interleaved events for two accounts and verifies that each account's events come back in send order.
