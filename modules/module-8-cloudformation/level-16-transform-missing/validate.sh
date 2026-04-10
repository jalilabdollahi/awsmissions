#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('template.yaml').read_text()
assert 'Transform: AWS::Serverless-2016-10-31' in text
INNER
echo "success"
