#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('alarm-rule.txt').read_text()
assert 'ALARM(alarm-a) AND ALARM(alarm-b)' in text
INNER
echo "success"
