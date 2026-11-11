# SEV-1 INC-8830 - Orders accepted, orders never recorded

Northstar Outfitters, web shop. Black Friday traffic is rising and the
operations dashboard shows 0 new orders in the ledger for the last 40 minutes.
Customers are being told "order received" (HTTP 202).

## Order pipeline

    storefront --POST /orders--> API Gateway (ns-orders-api, stage v1)
        --> Lambda ns-order-intake      (validates, enqueues)
        --> SQS ns-order-queue
        --> Lambda ns-order-writer      (event source mapping; writes the order)
        --> DynamoDB ns-orders

Order payload: `{"orderId": "o-1234", "sku": "mug-blue"}`.

## Timeline (UTC)
- 08:00  Weekly platform deploy, including a Terraform change that renamed
  and re-created several resources.
- 08:05  The ns-orders table was re-created to "match the new naming
  standard" (camelCase). A script copied its old items over... partly.
- 08:20  An engineer parked ns-order-writer to stop a noisy-neighbour
  alert, intending to un-park it after lunch.
- 08:35  Security tightened the intake function's role ("least privilege").
- 08:40  Config management refreshed the intake function's settings from a
  stale template.
- 08:55  Dashboard flatlines. Customers still get HTTP 202 because the intake
  function accepts the request before it knows whether the order was queued.

## Rules of engagement
- Do not lose orders that are already in `ns-orders` (the ledger holds
  `o-legacy-1`, which finance needs).
- The intake role may send to `ns-order-queue` and nothing else: the payments
  team's queue `ns-payments-queue` is in the same account.
- The on-call user `ns-oncall` can assume the intake role for debugging.
- Fix, don't rebuild: the API and the queue are fine as they are.
