# Solution

The bucket has no CORS configuration, so S3 answers the browser's preflight (`OPTIONS`) with 403 and the browser never sends the real request. curl does not do preflights, which is why it worked.

1. Confirm there is nothing configured:

```bash
aws s3api get-bucket-cors --bucket tidewater-pod-photos     # NoSuchCORSConfiguration
```

2. Fill in `cors.json` (`edit`):

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://dashboard.tidewater.example"],
      "AllowedMethods": ["GET", "PUT"],
      "AllowedHeaders": ["content-type"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```

3. Apply it:

```bash
aws s3api put-bucket-cors --bucket tidewater-pod-photos --cors-configuration file://cors.json
```

`AllowedOrigins: ["*"]` would also silence the browser error, but the validator sends a preflight from a foreign origin and from the dashboard with `DELETE` and expects both to be refused.
