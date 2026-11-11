# Debrief: where do failed async events go?

With asynchronous invocation Lambda queues the event internally and returns `202` at once. If your function fails, Lambda retries (twice by default, after 1 and then 2 minutes) and, when that is exhausted or the event is older than `MaximumEventAgeInSeconds`, **throws the event away**. You will not see an error anywhere unless you set up a place to catch it.

Two mechanisms exist:

| | Dead-letter queue (`DeadLetterConfig`) | Destinations (`DestinationConfig`) |
|---|---|---|
| Targets | SQS, SNS | SQS, SNS, EventBridge, another Lambda |
| Content | the original event only | event **plus** error type, message, stack trace, attempts |
| Covers success | no | yes (`OnSuccess`) |
| Status | older, still supported | AWS's recommendation for new work |

This mission uses a destination because the support team wants to see *why* each text failed: the delivered record carries `requestPayload` and `responsePayload.errorMessage`.

**The trap in the CLI:** `put-function-event-invoke-config` replaces the whole object, so omitting `--maximum-retry-attempts 0` silently turns retries back on. `update-function-event-invoke-config` merges. The checker verifies retries stayed at 0 because a retried SMS is a duplicate SMS.

**Permissions:** the function's execution role needs `sqs:SendMessage` (or `sns:Publish`, `events:PutEvents`, `lambda:InvokeFunction`) on the destination; that is already in place here.

**In real life**
- Alarm on queue depth (`ApproximateNumberOfMessagesVisible`) of the failure queue so someone looks.
- Make the handler idempotent where you can; then you can afford retries.
- Only *asynchronous* calls use these settings. A synchronous invoke returns the error straight to the caller. SQS-triggered functions use the queue's redrive policy instead.
