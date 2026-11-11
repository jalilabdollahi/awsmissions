# Solution

The manifest is larger than the 1 MiB SQS maximum, so no queue setting can make it fit. The standard answer is the **claim-check pattern**: put the payload in S3 and send only a reference through the queue.

1. Check the size and try the direct send to see the error:

```bash
ls -l payload/manifest.json
```

2. Upload the document unmodified:

```bash
aws s3api put-object --bucket quill-manifest-offload \
  --key manifests/2026-11-12.json --body payload/manifest.json
```

3. Send a small pointer message to the queue:

```bash
aws sqs send-message \
  --queue-url $(aws sqs get-queue-url --queue-name quill-manifest-jobs --query QueueUrl --output text) \
  --message-body '{"bucket":"quill-manifest-offload","key":"manifests/2026-11-12.json"}'
```

4. Run `check`. The validator reads the pointer from the queue, downloads the object it names, compares its checksum with the real manifest, and makes sure the queue message stayed small.
