#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

# The refund worker's subscription is the one whose endpoint is its queue.
sub="$(aws_local sns list-subscriptions --output json | python3 -c '
import json, sys
for s in json.load(sys.stdin)["Subscriptions"]:
    if s["Endpoint"].endswith(":cobalt-refund-worker"):
        print(s["SubscriptionArn"])
        break')"

aws_local sns set-subscription-attributes --subscription-arn "$sub" \
  --attribute-name FilterPolicyScope --attribute-value MessageBody
