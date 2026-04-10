#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('stack-policy.json').read_text()
assert 'ALLOW_UPDATE' in text
INNER
echo "success"
