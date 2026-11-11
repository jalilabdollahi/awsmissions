# Solution

S3 only calls a function when the **bucket's notification configuration** says so. The function permission already exists; the notification does not.

1. Confirm the bucket has no notification:

```bash
aws s3api get-bucket-notification-configuration --bucket helixia-lab-inbox
```

2. Complete the draft in your workspace (`edit notification.json`):
   - function ARN: `arn:aws:lambda:us-east-1:000000000000:function:lab-result-indexer`
   - event: `s3:ObjectCreated:*`
   - filters: prefix `results/`, suffix `.json`

3. Apply it:

```bash
aws s3api put-bucket-notification-configuration --bucket helixia-lab-inbox \
  --notification-configuration file://notification.json
```

4. Upload `results/test.json` and look the key up in `lab-result-index`.
