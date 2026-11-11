# Debrief: the transformation contract is strict, and strictness is a feature

When a delivery stream has a Lambda processor, Firehose sends it a batch (up to 6 MB or the configured buffer) and expects a response in exactly this shape:

```json
{"records": [{"recordId": "<as received>", "result": "Ok|Dropped|ProcessingFailed", "data": "<base64>"}]}
```

Rules that bite in practice
- **Same recordId, same count.** Firehose joins results to inputs by `recordId`; a missing or renamed id makes it treat the record as failed (`Lambda.MissingRecordId`). If *any* id is missing, the whole batch fails.
- **`result` is an enum.** `Ok` delivers the returned `data`; `Dropped` intentionally discards the record (filtering); `ProcessingFailed` sends the *original* record to the error prefix. Anything else is `Lambda.InvalidReturnFormat`.
- **`data` is base64** in both directions. Forgetting to encode (or double encoding) is the most common bug.
- **No separators.** Firehose writes records back to back. For JSON Lines, end each record with `\n`.
- **Exceptions are not row-level errors.** An uncaught exception fails the invocation; Firehose retries it (3 times by default) and then dumps the *entire batch* into the error prefix. Catch errors per record and return `ProcessingFailed` for the culprit only.

**Where failures land.** With `ErrorOutputPrefix` set, failed records go to `<prefix>processing-failed/...` (transformation) or `<prefix>format-conversion-failed/`, `<prefix>delivery-failed/`, etc. via `!{firehose:error-output-type}`. Each line is JSON with `rawData` (base64 of the original), `errorCode`, `errorMessage`, `attemptsMade` and `lambdaARN`, which is everything you need to debug or replay. Without an error prefix Firehose keeps failed data under a default folder in the bucket, and you should never rely on that.

**In real life**
- Test the function with a synthetic Firehose event locally (or via `aws lambda invoke`), as this level's validator does, before attaching it to a stream.
- Keep transformations fast and idempotent: a retried batch can transform the same records twice.
- Strip personal data in the transform (as here) so the raw payload never reaches the lake, and remember the original is still in `rawData` of the error files: protect that prefix too.
