# Solution

1. **Stream view type.** The stream was re-enabled as `KEYS_ONLY`, but the updater reads `NewImage`. A view type can only be set when a stream is enabled, so switch the stream off and back on with `NEW_IMAGE`.
2. **Mapping bound to a dead stream.** Re-enabling creates a new stream ARN. Delete the old event source mapping and create a new one against `describe-table ... LatestStreamArn`.
3. **Function configuration.** `LEADERBOARD_TABLE` is `orbit-leaderboards`; the table is `orbit-leaderboard`.
4. **Role.** The policy allows `PutItem`/`GetItem` but the function uses `UpdateItem`. Replace it with one that allows `dynamodb:UpdateItem` (and `GetItem`) on the leaderboard table ARN only.

`check` inspects stream spec, mapping, config and role behaviour (by invoking the function with a stream-shaped record), then writes a real workout and waits for the score to appear.
