#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

SECRET=sable/cdn/signing-key
current="$(aws_local secretsmanager get-secret-value --secret-id "$SECRET" --query SecretString --output text 2>/dev/null || true)"
if [ -z "$current" ]; then
  echo "Reading $SECRET failed."
  exit 1
fi
case "$current" in
  sk-fresh-c20d84) ;;
  sk-retired-7f31a9) echo "The default version still returns the retired key. The edge servers are still signing with it."; exit 1 ;;
  *) echo "The default version returns an unexpected value."; exit 1 ;;
esac

previous="$(aws_local secretsmanager get-secret-value --secret-id "$SECRET" --version-stage AWSPREVIOUS \
  --query SecretString --output text 2>/dev/null || true)"
if [ "$previous" != "sk-retired-7f31a9" ]; then
  echo "AWSPREVIOUS must hold the retired key for the overlap period (found: '${previous:-nothing}')."
  exit 1
fi

echo "AWSCURRENT serves the fresh signing key and AWSPREVIOUS keeps the retired one."
