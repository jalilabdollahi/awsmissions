#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# Read the wrong value the app sees, then repair the dangling Ref.
aws_local ssm get-parameter --name /tidewater/manifest-bucket --query Parameter.Value --output text
python3 - <<'PY'
import re
text = open("template.yaml").read()
text = re.sub(r"(!Ref\s+)ManifestBuket\b", r"\1ManifestBucket", text)
open("template.yaml", "w").write(text)
PY

aws_local cloudformation update-stack --stack-name tidewater-manifests \
  --template-body file://template.yaml >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name tidewater-manifests
