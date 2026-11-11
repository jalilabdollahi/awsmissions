# Solution

Resharding never moves records. It *closes* a shard and creates child shards: new writes go only to the children, while the data written before stays in the closed parent until it ages out. `export.py` hard-codes `shardId-000000000000`, the original shard. That shard is closed and holds only the entries from before the first reshard, so everything newer is invisible.

1. See the shard family tree, parents included:

```bash
aws kinesis list-shards --stream-name ledger-entries \
  --query 'Shards[].[ShardId,ParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output table
```

A shard with an `EndingSequenceNumber` is closed; its children list it as `ParentShardId`.

2. Make `export.py` (`edit`) discover shards at run time with `ListShards` (follow `NextToken`), read **every** shard from `TRIM_HORIZON` until it is exhausted, and process parents before children. Child shard ids are always higher than their parents', so sorting by id gives a valid order.

3. Deploy:

```bash
zip export.zip export.py
aws lambda update-function-code --function-name ledger-export --zip-file fileb://export.zip
```

4. `check` writes one fresh entry per account, invokes the function, and verifies that every entry appears exactly once and that each account's `seq` increases along the output.
