#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

bad=0
echo "cobalt-orders recovery check (INC-3318)"

# Collateral first: the legacy stack and its export must be exactly as they were.
core_export="$(aws_local cloudformation list-exports --query "Exports[?Name=='cobalt-orders-queue-arn'].Value | [0]" --output text 2>/dev/null || true)"
case "$core_export" in
  *cobalt-orders-legacy) ;;
  *) echo "The legacy export cobalt-orders-queue-arn no longer points at the legacy queue. cobalt-core's consumers depend on it; don't touch it."; exit 1 ;;
esac

# The ledger data: did the "delete and recreate" shortcut eat it?
memo="$(aws_local dynamodb get-item --table-name cobalt-ledger --key '{"entryId":{"S":"E-1"}}' --query 'Item.memo.S' --output text 2>/dev/null || true)"
if [ "$memo" != "opening balance" ]; then
  echo "DATA LOSS: ledger entry E-1 is gone from cobalt-ledger. That table held real finance data."
  exit 1
fi

# Fault 1: stack health.
status="$(aws_local cloudformation describe-stacks --stack-name cobalt-orders --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo MISSING)"
case "$status" in
  CREATE_COMPLETE|UPDATE_COMPLETE) echo "[ok]    stack  cobalt-orders is $status" ;;
  *) echo "[FAULT] stack  cobalt-orders is $status"; bad=$((bad + 1)) ;;
esac

# Fault 2: is it safe to delete in the future?
tpl="$(aws_local cloudformation get-template --stack-name cobalt-orders --query TemplateBody --output json 2>/dev/null || true)"
if printf '%s' "$tpl" | python3 -c '
import re, sys
text = sys.stdin.read().replace("\\n", "\n").replace("\\\"", "\"")
sys.exit(0 if re.search(r"DeletionPolicy\W+Retain", text) else 1)'; then
  echo "[ok]    data   the stack template protects a resource from deletion"
else
  echo "[FAULT] data   deleting this stack would destroy the ledger table"
  bad=$((bad + 1))
fi

# Fault 3: the function in the stack must be able to read the ledger it serves.
out="$(mktemp)"
rc=0
aws_local lambda invoke --function-name cobalt-ledger-fn --cli-binary-format raw-in-base64-out --payload '{}' "$out" >"$out.meta" 2>&1 || rc=$?
fn_table="$(aws_local lambda get-function-configuration --function-name cobalt-ledger-fn --query 'Environment.Variables.TABLE_NAME' --output text 2>/dev/null || echo None)"
if [ "$fn_table" != "cobalt-ledger" ]; then
  echo "[FAULT] code   cobalt-ledger-fn is not pointed at the ledger table ('$fn_table')"
  bad=$((bad + 1))
elif [ "$rc" -eq 0 ] && [ -z "$(jq -r '.FunctionError // empty' "$out.meta" 2>/dev/null)" ] && [ "$(jq -r '.status // empty' "$out" 2>/dev/null)" = "ledger-ok" ]; then
  echo "[ok]    code   cobalt-ledger-fn answers ledger-ok and can read the table"
else
  echo "[FAULT] code   cobalt-ledger-fn fails: $(jq -r '.errorMessage // empty' "$out" 2>/dev/null | cut -c1-130)"
  bad=$((bad + 1))
fi
rm -f "$out" "$out.meta"

# Fault 4: the stack must not shadow the legacy export.
dupes="$(aws_local cloudformation list-exports --query "length(Exports[?Name=='cobalt-orders-queue-arn'])" --output text 2>/dev/null || echo 0)"
mine="$(aws_local cloudformation describe-stacks --stack-name cobalt-orders --query "Stacks[0].Outputs[?ExportName=='cobalt-orders-queue-arn'] | length(@)" --output text 2>/dev/null || echo 0)"
if [ "$mine" != "0" ] && [ "$mine" != "None" ]; then
  echo "[FAULT] export cobalt-orders still tries to export a name that belongs to cobalt-core"
  bad=$((bad + 1))
else
  echo "[ok]    export no export-name collision with cobalt-core"
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) still wrong."
  exit 1
fi
echo "cobalt-orders is healthy, the ledger is intact and protected, cobalt-core is untouched."
