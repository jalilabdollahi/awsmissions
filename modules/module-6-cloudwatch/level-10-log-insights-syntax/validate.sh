#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('query.txt').read_text()
assert 'stats count() by bin(5m)' in text
INNER
echo "success"
