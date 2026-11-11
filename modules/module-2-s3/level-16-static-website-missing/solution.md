# Solution

Objects are only served as a *website* when the bucket has a website configuration. Without it, the website endpoint has nothing to apply: no index document for `/`, no folder handling, no custom error page.

1. Confirm there is no configuration:

```bash
aws s3api get-bucket-website --bucket driftwood-docs-site     # NoSuchWebsiteConfiguration
aws s3 ls s3://driftwood-docs-site/ --recursive
```

2. Fill in `website.json` (`edit`):

```json
{
  "IndexDocument": { "Suffix": "index.html" },
  "ErrorDocument": { "Key": "404.html" }
}
```

The index *suffix* is appended to any request that ends in `/`, which is how `/guides/` finds `guides/index.html`. The old `error.html` is not the one to point at.

3. Apply it:

```bash
aws s3api put-bucket-website --bucket driftwood-docs-site --website-configuration file://website.json
```

The validator requests `/`, `/guides/` and a missing page through the website endpoint.
