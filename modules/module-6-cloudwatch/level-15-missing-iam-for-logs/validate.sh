#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('policy.json').read_text()
assert 'logs:PutLogEvents' in text
INNER
echo "success"
