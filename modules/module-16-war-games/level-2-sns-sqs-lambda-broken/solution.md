# Solution

Four faults, one per hand-off in the chain:

1. **Filter policy.** The subscription only forwards `eventType: TicketPurchased`; checkout now sends `TicketSold`. Set the filter policy to `{"eventType":["TicketSold"]}`. Removing the filter altogether would let `TicketRefunded` events into the fulfilment table.
2. **Envelope.** `RawMessageDelivery` is `false`, so the queue holds the SNS notification JSON (`Type`, `MessageId`, `Message`...) and the fulfiller's `ticket["ticketId"]` raises `KeyError`. Set `RawMessageDelivery` to `true`.
3. **Event source mapping** is disabled. `aws lambda update-event-source-mapping --uuid ... --enabled`.
4. **Reserved concurrency is 0**, so every invocation is throttled. `aws lambda delete-function-concurrency` (or set a sensible positive value).

`check` inspects each stage, invokes the function directly with a probe record, and finally publishes one TicketSold and one TicketRefunded event through the real topic. The sale must reach DynamoDB and the refund must not.
