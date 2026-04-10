#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('incident.md').read_text()
assert 'lambda permission' in text
INNER
echo "success"
