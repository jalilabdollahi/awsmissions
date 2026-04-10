#!/usr/bin/env bash
set -euo pipefail
python3 - <<'INNER'
import json
from pathlib import Path
data = json.loads(Path('network.json').read_text())
assert str(data['PublicSubnet']) == 'subnet-public', f"PublicSubnet expected 'subnet-public', got {data.get('PublicSubnet')}"
assert str(data['PrivateSubnet']) == 'subnet-private', f"PrivateSubnet expected 'subnet-private', got {data.get('PrivateSubnet')}"
INNER
echo "success"
