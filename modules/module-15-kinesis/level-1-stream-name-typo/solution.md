# Solution

The function reads its destination from the `STREAM_NAME` environment variable. Monday's release set it to `thermowave-reading` (missing the final `s`), so every `PutRecord` call fails with `ResourceNotFoundException`.

1. Reproduce the error and compare names:

```bash
aws lambda invoke --function-name thermo-ingest --cli-binary-format raw-in-base64-out \
  --payload '{"device_id":"t-1","temp_c":21.5}' out.json && cat out.json
aws kinesis list-streams
aws lambda get-function-configuration --function-name thermo-ingest --query Environment
```

2. Set the correct name. `--environment` replaces the whole variable map, so repeat `FIRMWARE_CHANNEL` too:

```bash
aws lambda update-function-configuration --function-name thermo-ingest \
  --environment 'Variables={STREAM_NAME=thermowave-readings,FIRMWARE_CHANNEL=stable}'
```

3. Run `check`. The validator invokes the function with a fresh reading and reads that record back from the shard it landed on.
