#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('stack.txt').read_text()
assert 'DELETE_AND_RECREATE' in text
INNER
echo "success"
