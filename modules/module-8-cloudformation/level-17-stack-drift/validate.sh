#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('stack.txt').read_text()
assert 'RECONCILED' in text
INNER
echo "success"
