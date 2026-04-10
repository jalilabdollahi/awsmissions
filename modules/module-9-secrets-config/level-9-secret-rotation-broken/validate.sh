#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('config.json').read_text())
value = data
for part in 'rotationLambdaArn'.replace(']','').split('.'):
    if '[' in part:
        name, idx = part.split('[')
        value = value[name][int(idx)]
    else:
        value = value[part]
assert str(value) == 'arn:aws:lambda:us-east-1:000000000000:function:rotation-function'
INNER
echo "success"
