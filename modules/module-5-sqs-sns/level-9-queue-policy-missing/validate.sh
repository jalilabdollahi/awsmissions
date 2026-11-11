#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

topic_arn="arn:aws:sns:us-east-1:${ACCOUNT_ID}:ember-alerts"
queue_arn="arn:aws:sqs:us-east-1:${ACCOUNT_ID}:ember-pager-intake"
if ! url="$(aws_local sqs get-queue-url --queue-name ember-pager-intake --query QueueUrl --output text 2>/dev/null)"; then
  echo "ember-pager-intake does not exist."
  exit 1
fi

# The pipeline must still work end to end.
alert="disk-full-$(date +%s)-$$"
aws_local sns publish --topic-arn "$topic_arn" --message "$alert" >/dev/null
arrived() {
  aws_local sqs receive-message --queue-url "$url" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$alert"
}
if ! wait_for "alert delivery" 8 arrived; then
  echo "A published alert did not arrive in ember-pager-intake. Is the subscription still in place?"
  exit 1
fi

policy="$(aws_local sqs get-queue-attributes --queue-url "$url" --attribute-names Policy \
  --query 'Attributes.Policy' --output text 2>/dev/null || true)"
if [ -z "$policy" ] || [ "$policy" = "None" ]; then
  echo "ember-pager-intake has no queue policy. SNS (a different principal than your own account) is only allowed to write to a queue if its policy says so."
  exit 1
fi

# Evaluate what the policy would allow an SNS delivery to do.
verdict="$(POLICY="$policy" TOPIC="$topic_arn" QUEUE="$queue_arn" python3 - <<'PY'
import json, os

doc = json.loads(os.environ["POLICY"])
topic, queue = os.environ["TOPIC"], os.environ["QUEUE"]
stmts = doc.get("Statement", [])
if isinstance(stmts, dict):
    stmts = [stmts]

def as_list(v):
    return v if isinstance(v, list) else [v]

def principals(st):
    p = st.get("Principal")
    if p == "*":
        return ["*"]
    out = []
    for key, val in (p or {}).items():
        out += [(key, x) for x in as_list(val)]
    return out

def source_arns(st):
    cond = st.get("Condition", {})
    found = []
    for op in ("ArnEquals", "ArnLike"):
        for key, val in cond.get(op, {}).items():
            if key.lower() == "aws:sourcearn":
                found += as_list(val)
    return found

good = False
for st in stmts:
    if st.get("Effect") != "Allow":
        continue
    pr = principals(st)
    wide = pr == ["*"] or ("AWS", "*") in pr
    actions = [a.lower() for a in as_list(st.get("Action", []))]
    sends = any(a in ("sqs:sendmessage", "sqs:*", "*") for a in actions)
    sources = source_arns(st)
    if wide and not sources:
        print("open"); raise SystemExit
    if ("Service", "sns.amazonaws.com") in pr and sends:
        if "sqs:*" in actions or "*" in actions:
            print("wideaction"); raise SystemExit
        if queue not in as_list(st.get("Resource", [])):
            print("resource"); raise SystemExit
        if not sources:
            print("nosource"); raise SystemExit
        if any(s != topic for s in sources):
            print("othersource"); raise SystemExit
        good = True
print("ok" if good else "nosns")
PY
)"
case "$verdict" in
  ok) echo "SNS may deliver to ember-pager-intake, but only on behalf of ember-alerts. Alerts reach the pager." ;;
  open) echo "The policy lets any principal send to the queue. Allow only the SNS service, restricted to your topic."; exit 1 ;;
  wideaction) echo "The policy grants sqs:* to SNS. Delivery only needs sqs:SendMessage."; exit 1 ;;
  resource) echo "The statement for SNS does not name this queue's ARN as its Resource ($queue_arn)."; exit 1 ;;
  nosource) echo "SNS is allowed in, but from any topic in any account. Add a condition so only ember-alerts can write here (aws:SourceArn)."; exit 1 ;;
  othersource) echo "The aws:SourceArn condition allows more than the topic ember-alerts."; exit 1 ;;
  *) echo "The queue policy has no Allow statement for the SNS service principal with sqs:SendMessage."; exit 1 ;;
esac
