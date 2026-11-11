# Solution

Four properties drifted: the function's `Timeout` (3 to 30), `MemorySize` (128 to 512), its environment (`BATCH_SIZE` 50 to 150, plus a new `REGION_TAG=north`), and versioning on the bucket (off to on).

1. Compare reality with the stored template:

```bash
aws cloudformation get-template --stack-name tern-ingest
aws lambda get-function-configuration --function-name tern-ingest-fn
aws s3api get-bucket-versioning --bucket tern-ingest-landing
```

2. Edit `template.json` (`edit`) so it matches production:

```json
"Timeout": 30,
"MemorySize": 512,
"Environment": { "Variables": { "BATCH_SIZE": "150", "REGION_TAG": "north" } }
```

and on the bucket:

```json
"VersioningConfiguration": { "Status": "Enabled" }
```

3. Update the stack so the stored template is the corrected one:

```bash
aws cloudformation update-stack --stack-name tern-ingest --template-body file://template.json
aws cloudformation wait stack-update-complete --stack-name tern-ingest
```

4. `check` confirms the hotfix is still live, then compares the stack's stored template with the live function and bucket property by property.
