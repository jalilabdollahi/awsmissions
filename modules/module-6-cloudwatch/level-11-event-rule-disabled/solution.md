# Solution

An EventBridge rule only matches events while its **state** is `ENABLED`. Pattern and target are fine; the rule is `DISABLED` (as `rule.json` shows), so every event is ignored.

```bash
aws events describe-rule --name skyline-ticket-sold
aws events enable-rule --name skyline-ticket-sold
```

Alternatively set `"State": "ENABLED"` in `rule.json` and run `aws events put-rule --cli-input-json file://rule.json`. Run `check`: it publishes a TicketSold and a TicketRefunded event and looks at what lands in the queue.
