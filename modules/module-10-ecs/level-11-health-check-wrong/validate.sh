#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('task-definition.json').read_text())
value = data
for part in 'healthCheck[1]'.replace(']','').split('.'):
    if '[' in part:
        name, idx = part.split('[')
        value = value[name][int(idx)]
    else:
        value = value[part]
assert str(value) == 'curl -f http://localhost/health || exit 1'
INNER
echo "success"
