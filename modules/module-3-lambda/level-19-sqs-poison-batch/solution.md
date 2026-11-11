# Solution

Two halves have to change together: the function must say *which* messages failed, and the event source mapping must be told to listen for that.

1. Today the handler lets `json.loads` raise on the malformed body. An exception fails the **whole batch**, so Lambda leaves all messages in the queue; they reappear after the visibility timeout, the good ones are processed again, and after three receives all of them move to the DLQ.

2. Change the handler to catch per-record errors and return the failed message IDs (`edit processor.py`):

```python
def handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            ticket = json.loads(record["body"])
            ...  # ledger update as before
        except (ValueError, KeyError):
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
```

3. Deploy the code and enable partial batch responses on the mapping:

```bash
zip processor.zip processor.py
aws lambda update-function-code --function-name ticket-processor --zip-file fileb://processor.zip
aws lambda list-event-source-mappings --function-name ticket-processor
aws lambda update-event-source-mapping --uuid <uuid> --function-response-types ReportBatchItemFailures
```

Without step 3 the returned list is ignored and the malformed message would be treated as a success and deleted, which is worse than the original problem.
