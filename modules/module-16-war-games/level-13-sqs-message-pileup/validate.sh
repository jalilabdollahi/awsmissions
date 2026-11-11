#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

U="$AWS_ENDPOINT_URL/${ACCOUNT_ID}"
SQS="arn:aws:sqs:us-east-1:${ACCOUNT_ID}"
bad=0
echo "Sort-jobs pipeline review"

for q in pw-sort-jobs pw-sort-jobs-dlq pw-ops-pager; do
  if ! aws_local sqs get-queue-url --queue-name "$q" >/dev/null 2>&1; then
    echo "Queue $q is gone. Repair it; don't delete queues."
    exit 1
  fi
done

attrs="$(aws_local sqs get-queue-attributes --queue-url "$U/pw-sort-jobs" --attribute-names All --query Attributes --output json)"
redrive="$(printf '%s' "$attrs" | jq -r '.RedrivePolicy // "{}"')"
target="$(printf '%s' "$redrive" | jq -r '.deadLetterTargetArn // ""')"
maxrc="$(printf '%s' "$redrive" | jq -r '.maxReceiveCount // 0')"
vis="$(printf '%s' "$attrs" | jq -r '.VisibilityTimeout')"

# Fault 1: where do failed messages go?
if [ "$target" = "$SQS:pw-sort-jobs-dlq" ]; then
  echo "[ok]    redrive  failed messages are routed to pw-sort-jobs-dlq"
else
  echo "[FAULT] redrive  the source queue's dead-letter target (${target:-none}) is not the DLQ"
  bad=$((bad + 1))
fi
# Fault 2: how many tries?
if [ "$maxrc" -ge 1 ] && [ "$maxrc" -le 5 ]; then
  echo "[ok]    redrive  a failing message is parked after $maxrc receives"
else
  echo "[FAULT] redrive  a failing message would be received $maxrc times before being parked (agreed: at most 5)"
  bad=$((bad + 1))
fi
# Fault 3: time a worker gets.
if [ "$vis" -ge 30 ]; then
  echo "[ok]    timing   workers get ${vis}s per message before it is handed on"
else
  echo "[FAULT] timing   a worker gets only ${vis}s per message but a parcel takes up to 30s"
  bad=$((bad + 1))
fi
# Fault 4: the page.
alarm="$(aws_local cloudwatch describe-alarms --output json --query 'MetricAlarms[?MetricName==`ApproximateNumberOfMessagesVisible`]' \
  | jq -c '[.[] | select([.Dimensions[]? | select(.Name == "QueueName" and .Value == "pw-sort-jobs-dlq")] | length > 0)] | first // empty')"
alarm_name=""
if [ -z "$alarm" ]; then
  echo "[FAULT] paging   nothing watches the depth of pw-sort-jobs-dlq"
  bad=$((bad + 1))
else
  alarm_name="$(printf '%s' "$alarm" | jq -r '.AlarmName')"
  thr="$(printf '%s' "$alarm" | jq -r '.Threshold')"
  op="$(printf '%s' "$alarm" | jq -r '.ComparisonOperator')"
  acts="$(printf '%s' "$alarm" | jq -r '.AlarmActions | length')"
  if [ "$acts" = "0" ]; then
    echo "[FAULT] paging   alarm $alarm_name watches the DLQ but notifies nobody"
    bad=$((bad + 1))
  else
    case "$op" in
      GreaterThanThreshold) okop=$([ "${thr%.*}" -lt 1 ] && echo y || echo n) ;;
      GreaterThanOrEqualToThreshold) okop=$([ "${thr%.*}" -le 1 ] && echo y || echo n) ;;
      *) okop=n ;;
    esac
    if [ "$okop" = "y" ]; then
      echo "[ok]    paging   alarm $alarm_name watches the DLQ and has an action"
    else
      echo "[FAULT] paging   alarm $alarm_name would not trip when a single message sits in the DLQ"
      bad=$((bad + 1))
    fi
  fi
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad item(s) still broken. No live messages sent yet."
  exit 1
fi

# Live replay: a scratch queue with exactly the source queue's redrive settings and a
# poison message that is received (and never deleted) like a crashing worker would.
id="$(date +%s)"
probe="pw-sort-probe-$id"
pf="$(mktemp)"
printf '%s' "$attrs" | jq '{RedrivePolicy: .RedrivePolicy, VisibilityTimeout: "1"}' > "$pf"
aws_local sqs purge-queue --queue-url "$U/pw-ops-pager" >/dev/null 2>&1 || true
aws_local cloudwatch set-alarm-state --alarm-name "$alarm_name" --state-value OK --state-reason "validation reset" >/dev/null 2>&1 || true
aws_local sqs create-queue --queue-name "$probe" --attributes "file://$pf" >/dev/null
rm -f "$pf"
aws_local sqs send-message --queue-url "$U/$probe" --message-body "{\"id\":\"poison-$id\",\"poison\":true}" >/dev/null
n=0
while [ "$n" -lt $((maxrc + 2)) ]; do
  aws_local sqs receive-message --queue-url "$U/$probe" --visibility-timeout 1 >/dev/null 2>&1 || true
  sleep 2
  n=$((n + 1))
done
parked() {
  aws_local sqs receive-message --queue-url "$U/pw-sort-jobs-dlq" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "poison-$id"
}
if ! wait_for "poison message in the DLQ" 15 parked; then
  aws_local sqs delete-queue --queue-url "$U/$probe" >/dev/null 2>&1 || true
  echo "A replayed poison message was received $n times but never reached pw-sort-jobs-dlq."
  exit 1
fi
aws_local sqs delete-queue --queue-url "$U/$probe" >/dev/null 2>&1 || true
paged() {
  aws_local sqs receive-message --queue-url "$U/pw-ops-pager" --max-number-of-messages 10 --visibility-timeout 0 \
    --query 'Messages[].Body' --output text 2>/dev/null | grep -q "$alarm_name"
}
if ! wait_for "ops page" 45 paged; then
  echo "The poison message sits in the DLQ but ops was not paged: the alarm never reached pw-ops-pager."
  exit 1
fi
echo "A replayed poison message was parked after $maxrc receives and ops was paged. The next bad record will not take down the hub."
