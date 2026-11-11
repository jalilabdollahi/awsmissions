# Solution

The `thumbnail-on-upload` rule listens for `s3:ObjectRemoved:*`, the event fired by deletes. It was probably copy-pasted from the audit rule just below it. Uploads fire `s3:ObjectCreated:*` events, which nothing was subscribed to.

1. Read what is configured:

```bash
aws s3api get-bucket-notification-configuration --bucket snapfolio-gallery
```

2. In `notification.json` change only the first rule's event:

```json
"Id": "thumbnail-on-upload",
"Events": ["s3:ObjectCreated:*"]
```

3. Send the complete document, because the API replaces the whole configuration (sending only the first rule would remove the audit rule):

```bash
aws s3api put-bucket-notification-configuration --bucket snapfolio-gallery \
  --notification-configuration file://notification.json
```

The validator uploads and deletes objects under both prefixes and reads both queues to make sure each one only sees what it should.
