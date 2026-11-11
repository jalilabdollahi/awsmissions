# Solution

`audit.py` asks Kinesis for an iterator of type `LATEST`: "start just after the newest record". Since the audit runs at night, after the day's traffic, it always starts at the end of the shard and sees nothing, without ever raising an error. To read what the stream still retains, start at the oldest record with `TRIM_HORIZON`.

1. Reproduce:

```bash
aws lambda invoke --function-name swipe-audit --cli-binary-format raw-in-base64-out --payload '{}' out.json && cat out.json
aws kinesis get-shard-iterator --stream-name card-swipes --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON
```

2. In `audit.py` (`edit`) change `ShardIteratorType="LATEST"` to `ShardIteratorType="TRIM_HORIZON"`.

3. Package and deploy:

```bash
zip audit.zip audit.py
aws lambda update-function-code --function-name swipe-audit --zip-file fileb://audit.zip
```

4. `check` puts one more swipe into the stream, invokes the function and expects all seven.
