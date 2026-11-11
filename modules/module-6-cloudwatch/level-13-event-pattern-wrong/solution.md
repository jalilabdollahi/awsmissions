# Solution

An event pattern matches **exactly and case-sensitively**. The pattern in `pattern.json` has two mismatches with the real events:

- `source` is `quillshop.order`, but the shop publishes `quillshop.orders`.
- `detail.tier` is `Gold`, but the events carry `gold`.

You can prove it with `test-event-pattern` before touching the rule:

```bash
aws events test-event-pattern --event-pattern file://pattern.json --event '{"id":"1","account":"000000000000","time":"2026-11-11T10:00:00Z","region":"us-east-1","version":"0","resources":[],"source":"quillshop.orders","detail-type":"OrderPlaced","detail":{"tier":"gold"}}'
```

Fix both values in `pattern.json` and update the rule (`put-rule` with an existing name replaces it):

```bash
aws events put-rule --name quillshop-gold-orders --state ENABLED --event-pattern file://pattern.json
```

Run `check`: it publishes gold, silver and cancelled events and looks at what reaches the queue.
