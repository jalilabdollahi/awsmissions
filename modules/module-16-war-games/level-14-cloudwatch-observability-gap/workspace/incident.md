# Postmortem PM-2026-31: "Checkout was failing for 47 minutes and our dashboards were green"

Tallow & Finch (home goods e-commerce). Author: SRE rota.

## Impact
On 2026-11-04 between 19:12 and 19:59 UTC the checkout Lambda declined or
errored on roughly one order in three (payment provider outage). Neither
the CheckoutFailures alarm nor the on-call page fired.

## What the function logs (JSON, one line per event)

    {"level": "INFO",  "order": "o-1832", "msg": "charged"}
    {"level": "ERROR", "order": "o-1833", "code": "CARD_DECLINED", "msg": "payment failed"}

The Lambda is `tf-checkout-fn`; Lambda writes to the log group
`/aws/lambda/tf-checkout-fn`. To simulate a failing order, invoke it with
`{"fail": true}`.

## Observability design we thought we had
1. Metric filter on the function's log group counts ERROR lines into
   `TF/Checkout` -> `CheckoutFailures`.
2. Alarm `tf-checkout-errors` trips on 5+ failures within 10 seconds.
3. Production pages go through SNS topic `tf-oncall` (subscribed by the pager
   bridge queue `tf-oncall-inbox`). The topic `tf-alerts-dev` is a sandbox
   topic that goes nowhere.

## Contributing factors found by the review
- Lambda was renamed from `tf-checkout-fn-old` in the spring. The log group
  of the old function still exists.
- The metric filter was written for the structured-logging spec draft (it uses
  the field name from the draft, not the one we shipped).
- The metric filter's namespace and the alarm's namespace were typed by two
  different people.
- The alarm was copied from the staging environment.

## Remediation (this ticket)
Make the alert real, and prove it with a failing order, not with a diff.
