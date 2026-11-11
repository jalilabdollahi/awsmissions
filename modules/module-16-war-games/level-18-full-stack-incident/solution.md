# Solution

1. **Intake configuration.** `QUEUE_URL` points at `ns-orders-queue` (plural). Set it to `.../ns-order-queue`.
2. **Intake role.** The policy has no SQS statement. Add `sqs:SendMessage` on the order queue's ARN only (not `*`: the payments team's queue shares the account).
3. **Writer concurrency.** Reserved concurrency is 0. `aws lambda delete-function-concurrency --function-name ns-order-writer`.
4. **Table key schema.** The re-created table keys on `order_id`, the writer stores `orderId`, so every `PutItem` fails with a ValidationException. A DynamoDB key schema cannot be changed in place: export the rows (`scan`), delete the table, create it again with `orderId` as the hash key, and import the rows with the key attribute renamed so `o-legacy-1` survives. (Changing the writer's code to use `order_id` would also work, but is a code deploy.)

`check` triages each stage (including a direct invocation of the writer and a send as the intake role, and confirms the role cannot send to the payments queue), then POSTs a real order to `/v1/orders` and waits for it to appear in `ns-orders`, while the legacy row must still be there.
