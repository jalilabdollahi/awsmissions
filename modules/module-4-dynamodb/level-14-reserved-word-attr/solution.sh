#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
p = "close-ticket.sh"
s = open(p).read()
s = s.replace('--update-expression "SET status = :closed, comment = :note, timestamp = :now"',
              '--update-expression "SET #st = :closed, #co = :note, #ts = :now" \\\n  --expression-attribute-names \'{"#st":"status","#co":"comment","#ts":"timestamp"}\'')
open(p, "w").write(s)
PY
bash ./close-ticket.sh tk-77 "Refund issued to original card"
