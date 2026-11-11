# Solution

The function simply does not exist, so there is nothing to invoke. Create it from the code in your workspace.

1. Package the source. The zip must have `label_builder.py` at its root:

```bash
zip label_builder.zip label_builder.py
```

2. Create the function. The handler is `<file name without .py>.<function name>`, so `label_builder.build_label`. Reuse the role that is already there:

```bash
aws lambda create-function \
  --function-name parcel-label-formatter \
  --runtime python3.12 \
  --handler label_builder.build_label \
  --role arn:aws:iam::000000000000:role/parcel-label-role \
  --zip-file fileb://label_builder.zip
```

3. Test it the way the dispatch job does:

```bash
aws lambda invoke --function-name parcel-label-formatter \
  --cli-binary-format raw-in-base64-out \
  --payload '{"city":"Tacoma","state":"wa","zip":"98402","weight_kg":2.5}' out.json
cat out.json
```
