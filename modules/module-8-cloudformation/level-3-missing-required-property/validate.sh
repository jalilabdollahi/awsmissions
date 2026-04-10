#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('template.yaml').read_text()
assert 'AssumeRolePolicyDocument' in text
INNER
echo "success"
