# Ticket TT-5530 - "Sold tickets never reach fulfilment"

Tidewater Tickets, box-office platform team. Reported by customer support, 11:05.

## Customer impact
Customers pay, get a "thank you" page, and then never receive their seat
confirmation e-mail. Fulfilment's dashboard has shown 0 sold tickets since the
Tuesday release.

## Architecture (as drawn on the whiteboard)

    checkout --publish--> SNS tt-ticket-events
                            |  (only TicketSold events are wanted; refunds go elsewhere)
                            v
                         SQS tt-ticket-fulfilment
                            |  event source mapping
                            v
                         Lambda tt-ticket-fulfiller --> DynamoDB tt-fulfilled-tickets

The checkout service publishes the JSON body `{"ticketId": "...", "seat": "..."}`
with a message attribute `eventType` (`TicketSold` or `TicketRefunded`).

## Notes from the release
- "Renamed the event from TicketPurchased to TicketSold in checkout."
- "Ops tidied the fulfiller's settings before the freeze."
- "Switched the subscription to the new topic. Delivery format is whatever the
  console defaulted to."

## Ask
Make a TicketSold event arrive in tt-fulfilled-tickets again. TicketRefunded
events must keep staying out of that table.
