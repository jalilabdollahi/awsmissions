#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

python3 - <<'PY'
text = open("template.yaml").read()
trust = """      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub "arn:aws:iam::${AWS::AccountId}:user/export-runner"
            Action: sts:AssumeRole
"""
marker = "      RoleName: lumen-exporter\n"
open("template.yaml", "w").write(text.replace(marker, marker + trust))
PY

aws_local cloudformation update-stack --stack-name lumen-export \
  --template-body file://template.yaml --capabilities CAPABILITY_NAMED_IAM >/dev/null
aws_local cloudformation wait stack-update-complete --stack-name lumen-export
