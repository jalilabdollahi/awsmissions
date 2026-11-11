# Solution

Enable the stream with the view type that includes both images:

```bash
aws dynamodb update-table \
  --table-name greenroom-articles \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
```

Verify:

```bash
aws dynamodb describe-table --table-name greenroom-articles --query 'Table.[StreamSpecification,LatestStreamArn]'
```

`KEYS_ONLY` or `NEW_IMAGE` alone would satisfy "a stream exists", but not "what was the headline before".
