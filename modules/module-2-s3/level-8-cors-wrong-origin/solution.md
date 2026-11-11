# Solution

The `admin-editor` rule is wrong in two ways:

- its origin is `https://admin.brightcart.example/` with a **trailing slash**. A browser's `Origin` header never has one, and S3 compares origins as exact strings, so the rule never matches;
- its `AllowedMethods` only lists `GET`, but the admin app also uses `PUT` and `DELETE`.

1. Read the live configuration:

```bash
aws s3api get-bucket-cors --bucket brightcart-media
```

2. In `cors.json` change the admin rule to:

```json
"AllowedOrigins": ["https://admin.brightcart.example"],
"AllowedMethods": ["GET", "PUT", "DELETE"]
```

Leave the `storefront-readonly` rule alone.

3. `put-bucket-cors` replaces the whole configuration, so apply the complete file:

```bash
aws s3api put-bucket-cors --bucket brightcart-media --cors-configuration file://cors.json
```
