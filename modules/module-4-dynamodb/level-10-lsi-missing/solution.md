# Solution

A local secondary index can only be declared in `create-table`. There is no `update-table` operation for it, so the table has to be rebuilt:

1. Save the data:

```bash
aws dynamodb scan --table-name clinic-appointments --output json > appointments-dump.json
```

2. Delete the table and recreate it with the LSI (the new sort-key attribute `severity` must be in the attribute definitions):

```bash
aws dynamodb delete-table --table-name clinic-appointments
aws dynamodb create-table --cli-input-json file://create-table.json
```

`workspace/create-table.json` holds the current table definition to extend with `LocalSecondaryIndexes`.

3. Put the items back. The scan output is already in DynamoDB JSON, so each element of `Items` can be given to `put-item --item` unchanged (or use `batch-write-item` in batches of 25).
