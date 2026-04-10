#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh

aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local iam create-role   --role-name bounded-reader-role   --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::000000000000:root"},"Action":"sts:AssumeRole"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-policy   --role-name bounded-reader-role   --policy-name identity-reader-policy   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null
aws_local iam create-policy   --policy-name deny-s3-boundary   --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null 2>&1 || true
aws_local iam put-role-permissions-boundary   --role-name bounded-reader-role   --permissions-boundary arn:aws:iam::000000000000:policy/deny-s3-boundary >/dev/null

echo "Broken IAM role created: bounded-reader-role (boundary blocks S3)"
