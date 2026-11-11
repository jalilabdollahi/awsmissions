#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
text = open("export.py").read()
text = text.replace('''# The stream has a single shard.
SHARD_IDS = ["shardId-000000000000"]
''', '''def all_shard_ids():
    # ListShards returns open and closed shards. A child always has a higher id
    # than its parent, so ascending order reads parents before children.
    ids, token = [], None
    while True:
        if token:
            page = kinesis.list_shards(NextToken=token)
        else:
            page = kinesis.list_shards(StreamName=STREAM)
        ids.extend(s["ShardId"] for s in page["Shards"])
        token = page.get("NextToken")
        if not token:
            break
    return sorted(ids, key=lambda s: int(s.split("-")[1]))
''')
text = text.replace("for shard_id in SHARD_IDS:", "for shard_id in all_shard_ids():")
open("export.py", "w").write(text)
PY

rm -f export.zip
zip -q export.zip export.py
aws_local lambda update-function-code --function-name ledger-export --zip-file fileb://export.zip >/dev/null
wait_for "function update" 30 aws_local lambda wait function-updated --function-name ledger-export
