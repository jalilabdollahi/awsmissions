# Solution

1. **Log group.** The only metric filter lives on `/aws/lambda/tf-checkout-fn-old`. Create it on `/aws/lambda/tf-checkout-fn` and delete the stale one.
2. **Pattern.** `{ $.severity = "ERROR" }` matches a field the function never logs. The function logs `level`, so use `{ $.level = "ERROR" }` (INFO lines must stay out).
3. **Namespace.** The filter emits `TF/Checkouts`, the alarm watches `TF/Checkout`. Use the same namespace and metric name on both sides (the example uses `TF/Checkout`, `CheckoutFailures`).
4. **Alarm action.** The alarm notifies `tf-alerts-dev`, which has no subscribers. Re-run `put-metric-alarm` with the `tf-oncall` topic ARN (the topic that feeds `tf-oncall-inbox`).

`check` tests the filter pattern with real log-line samples, compares the filter's and alarm's metric, follows the alarm's action to the queue, and then really invokes the function six times with `fail: true` (plus two successes) and waits for the page in `tf-oncall-inbox`.
