# Solution

The delivery stream works, so nothing errors, but its S3 destination points at a bucket called `harborview-data-lake` (with a hyphen) and writes under `events/`. The Athena table reads `harborview-datalake` and `clicks/dt=YYYY-MM-DD/`.

1. Read the destination and look for the stray bucket:

```bash
aws firehose describe-delivery-stream --delivery-stream-name clickstream-to-lake
aws s3 ls
```

2. Fix `destination.json` (`edit`): `BucketARN` becomes `arn:aws:s3:::harborview-datalake` and `Prefix` becomes `clicks/dt=!{timestamp:yyyy-MM-dd}/`. The `!{timestamp:...}` expression is evaluated by Firehose at delivery time (UTC), so every day gets its own folder.

3. Update the destination. You need the delivery stream's current version id and the destination id from `describe-delivery-stream` (normally `1` and `destinationId-000000000001`):

```bash
aws firehose update-destination --delivery-stream-name clickstream-to-lake \
  --current-delivery-stream-version-id 1 \
  --destination-id destinationId-000000000001 \
  --extended-s3-destination-update file://destination.json
```

4. `check` sends a click event and waits for an object under `clicks/dt=<today>/` in `harborview-datalake` that contains it.
