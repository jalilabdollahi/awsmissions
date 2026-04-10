#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
from pathlib import Path
text = Path('template.yaml').read_text()
assert 'TemplateURL' in text, "TemplateURL property must be present"
assert 'wrong-bucket' not in text, "TemplateURL still points to wrong-bucket — fix the S3 path"
assert 'mission-bucket' in text, "TemplateURL must point to mission-bucket"
INNER
echo "success"
