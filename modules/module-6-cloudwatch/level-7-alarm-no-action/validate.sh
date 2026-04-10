#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('alarm.json').read_text())
value = data
for part in 'AlarmActions[0]'.replace(']','').split('.'):
    if '[' in part:
        name, idx = part.split('[')
        value = value[name][int(idx)]
    else:
        value = value[part]
assert str(value) == 'arn:aws:sns:us-east-1:000000000000:mission-topic'
INNER
echo "success"
