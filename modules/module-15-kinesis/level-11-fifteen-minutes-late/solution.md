# Solution

Firehose does not deliver each record: it **buffers** them and writes one object when either buffer limit is reached, whichever comes first: `SizeInMBs` (here 128) or `IntervalInSeconds` (here 900). A modest fraud-signal rate never reaches 128 MB, so every signal waits the full 15 minutes.

1. Read the current hints:

```bash
aws firehose describe-delivery-stream --delivery-stream-name fraud-signals-to-s3 \
  --query 'DeliveryStreamDescription.Destinations[0].ExtendedS3DestinationDescription.[BufferingHints,CompressionFormat]'
```

2. Edit `buffering.json` (`edit`): lower `IntervalInSeconds` to something small but not tiny (for example 20) and add `"CompressionFormat": "GZIP"` at the top level of the document.

3. Apply it:

```bash
aws firehose update-destination --delivery-stream-name fraud-signals-to-s3 \
  --current-delivery-stream-version-id 1 \
  --destination-id destinationId-000000000001 \
  --extended-s3-destination-update file://buffering.json
```

4. `check` rejects intervals under 5 seconds, sends a signal, and waits for a gzip object under `signals/` that decompresses to contain it.
