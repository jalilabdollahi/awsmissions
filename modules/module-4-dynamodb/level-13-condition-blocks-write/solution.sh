#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
p = "ship-orders.sh"
s = open(p).read()
s = s.replace('--condition-expression "attribute_not_exists(orderId)"',
              '--condition-expression "#s = :packed" ')
s = s.replace('\\":one\\":{\\"N\\":\\"1\\"}}"', '\\":one\\":{\\"N\\":\\"1\\"},\\":packed\\":{\\"S\\":\\"PACKED\\"}}"')
open(p, "w").write(s)
PY
bash ./ship-orders.sh
