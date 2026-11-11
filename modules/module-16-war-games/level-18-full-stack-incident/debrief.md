# Debrief: INC-8830, orders accepted and then vanish

## Root causes
| # | Stage | Fault |
|---|---|---|
| 1 | Intake configuration | Stale template: queue name `ns-orders-queue` instead of `ns-order-queue` |
| 2 | Intake IAM | "Least privilege" removed `sqs:SendMessage` entirely |
| 3 | Writer Lambda | Parked at reserved concurrency 0, never un-parked |
| 4 | DynamoDB | Re-created table keyed `order_id` while the code writes `orderId` |

## Timeline
- 08:00 deploy with renames. 08:05 table re-created; the data copy was partial and the key attribute differed.
- 08:20 writer parked. 08:35 intake role tightened. 08:40 configuration refreshed from a stale template.
- 08:55 dashboard flatlines. Customers keep seeing "order received" because the intake function catches enqueue errors, logs them and still returns HTTP 202, so the storefront never learns that the order was not queued.

## Why this took the whole hour
Four independent changes by four people in one morning. Any one of them would have broken the pipeline; together they hide each other. The fix order matters for diagnosis: you cannot see the table problem until the writer runs, or the writer's concurrency until orders reach the queue.

## Lessons
- Observe the pipeline end to end: orders accepted per minute, orders stored per minute, queue depth, queue age, Lambda throttles and errors, DLQ depth. A divergence between the first two numbers is your alert.
- Make the first hop honest. An intake that returns 202 must have actually enqueued (fail the request when `send_message` fails).
- Change one thing at a time in production and write down every kill switch you flip (concurrency 0 is the classic forgotten one).
- A DynamoDB key schema is immutable: migrate by copy, not by edit, and verify the row count afterwards.
- Least privilege is the goal, but test every function after tightening a role; automate that smoke test.
