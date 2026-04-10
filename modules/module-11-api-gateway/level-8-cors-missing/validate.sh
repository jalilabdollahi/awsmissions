#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('cors.json').read_text())
value = data
for part in 'allowOrigin'.replace(']','').split('.'):
    if '[' in part:
        name, idx = part.split('[')
        value = value[name][int(idx)]
    else:
        value = value[part]
assert str(value) == '*'
INNER
echo "success"
