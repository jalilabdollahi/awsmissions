#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('template.yaml').read_text()
assert 'mission-SharedBucketName' in text, "ExportName must be changed to a unique name (e.g. mission-SharedBucketName)"
assert 'SharedBucketName' not in text.replace('mission-SharedBucketName', ''), "Plain 'SharedBucketName' (duplicate name) must be removed"
INNER
echo "success"
