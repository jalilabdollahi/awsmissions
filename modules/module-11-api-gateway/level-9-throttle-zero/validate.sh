#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('stage.json').read_text())
value = data
for part in 'throttlingBurstLimit'.replace(']','').split('.'):
    if '[' in part:
        name, idx = part.split('[')
        value = value[name][int(idx)]
    else:
        value = value[part]
assert str(value) == '100'
INNER
echo "success"
