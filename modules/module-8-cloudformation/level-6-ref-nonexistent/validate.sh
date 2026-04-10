#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('template.yaml').read_text()
assert 'REF MyBucket' in text, "Output must still reference MyBucket"
assert 'MyBucket' in text and ('Type:' in text or 'type:' in text), "MyBucket resource must be defined in the template"
INNER
echo "success"
