#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

body="$(aws_local cloudwatch get-dashboard --dashboard-name rivergate-payments \
  --query DashboardBody --output text 2>/dev/null || true)"
if [ -z "$body" ]; then
  echo "The dashboard rivergate-payments does not exist. Update it, do not delete it."
  exit 1
fi

# Pull the widget's query apart the way the console does: SOURCE '<group>' | <query>.
parsed="$(DASH="$body" python3 - <<'PY'
import json, os, re
doc = json.loads(os.environ["DASH"])
for w in doc.get("widgets", []):
    q = w.get("properties", {}).get("query")
    if w.get("type") == "log" and q:
        m = re.match(r"\s*SOURCE\s+'([^']+)'\s*\|\s*(.*)$", q, re.S)
        if m:
            print(m.group(1))
            print(m.group(2))
            raise SystemExit
print("")
PY
)"
group="$(printf '%s\n' "$parsed" | sed -n 1p)"
query="$(printf '%s\n' "$parsed" | sed -n '2,$p')"
if [ -z "$group" ] || [ -z "$query" ]; then
  echo "The dashboard has no Logs Insights widget with a 'SOURCE ... | query' definition any more."
  exit 1
fi

now="$(date +%s)"
if ! qid="$(aws_local logs start-query --log-group-name "$group" --start-time $((now - 3600)) \
  --end-time $((now + 60)) --query-string "$query" --query queryId --output text 2>&1)"; then
  echo "The widget cannot even start its query on '$group': $(printf '%s' "$qid" | tail -1)"
  exit 1
fi

res="$(mktemp)"
trap 'rm -f "$res"' EXIT
done_q() {
  aws_local logs get-query-results --query-id "$qid" --output json > "$res" 2>/dev/null &&
    python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["status"] in ("Complete","Failed") else 1)' "$res"
}
wait_for "query to finish" 15 done_q || { echo "The widget's query never finished."; exit 1; }

verdict="$(python3 - "$res" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
if d["status"] != "Complete":
    print("failed"); raise SystemExit
errors = 0
other = 0
for row in d["results"]:
    text = " ".join(f["value"] for f in row if f["field"] != "@ptr")
    if '"ERROR"' in text or "ERROR" in text:
        errors += 1
    else:
        other += 1
print("rows %d other %d" % (errors, other))
PY
)"
case "$verdict" in
  failed) echo "Logs Insights rejected the widget's query."; exit 1 ;;
  "rows 0 other 0") echo "The widget's query runs on /rivergate/payments but returns no rows at all. Insights field names are case-sensitive and must be spelled as they appear in the JSON."; exit 1 ;;
  "rows 3 other 0") echo "The widget now lists exactly the three ERROR entries." ;;
  *) echo "The widget returns [$verdict] (ERROR rows / other rows). It should return exactly the 3 ERROR entries of /rivergate/payments."; exit 1 ;;
esac
