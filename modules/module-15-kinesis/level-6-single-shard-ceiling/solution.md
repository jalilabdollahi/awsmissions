# Solution

Each shard accepts 1 MB/s (or 1,000 records/s) of writes, so capacity is simply `shards x 1 MB/s`. A 3 MB/s peak needs at least three open shards. Resharding is done in place with `UpdateShardCount`, and the history stays readable.

1. Look at the current layout:

```bash
aws kinesis describe-stream-summary --stream-name charger-heartbeats --query StreamDescriptionSummary.OpenShardCount
aws kinesis list-shards --stream-name charger-heartbeats
```

2. One call can at most **double** the number of open shards, so a jump from 1 to 4 takes two steps:

```bash
aws kinesis update-shard-count --stream-name charger-heartbeats --target-shard-count 2 --scaling-type UNIFORM_SCALING
aws kinesis update-shard-count --stream-name charger-heartbeats --target-shard-count 4 --scaling-type UNIFORM_SCALING
```

(Going 1 to 2 to 3 also satisfies the brief; anything from 3 to 6 does.)

3. `check` sends 40 heartbeats from different chargers, verifies they spread over at least three shards, and reads every shard (including the closed parents) to make sure the four original heartbeats are still there.
