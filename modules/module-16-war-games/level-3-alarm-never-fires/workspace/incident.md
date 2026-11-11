# Postmortem draft PM-77: "We found out from Twitter"

Kestrel Payments - settlement platform.

On Saturday between 02:10 and 05:50 UTC the settlement API rejected roughly 40%
of batch submissions. The on-call engineer was never paged. A merchant noticed
and posted about it.

## What the logs looked like (log group /kp/settlement-api)

    2026-11-07T02:11:04Z level=ERROR code=SETTLE_TIMEOUT batch=B-90113 merchant=m-482
    2026-11-07T02:11:09Z level=INFO  code=SETTLED batch=B-90114
    2026-11-07T02:11:17Z level=ERROR code=LEDGER_LOCKED batch=B-90115 merchant=m-77

Nothing in the app is `FATAL`; "error" is the normal failure level here.

## Monitoring design (what we *intended*)
- Metric filter turns each ERROR line into one data point of
  `KP/Settlement` -> `SettlementErrors`.
- Alarm `kp-settlement-errors` goes into ALARM when 5 or more errors land in a
  10 second window.
- The alarm notifies SNS topic `kp-oncall-pager`. The pager bridge consumes the
  SQS queue `kp-pager-inbox`, which is subscribed to that topic.

## Action items
- Make the alert real again. Prove it by generating errors and watching the
  pager queue, not by reading config.
- Do not "fix" it by alarming on every log line; that is how we got alert
  fatigue last quarter.
