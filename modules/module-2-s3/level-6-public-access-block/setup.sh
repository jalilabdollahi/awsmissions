#!/usr/bin/env bash
set -euo pipefail
source ../../../scripts/aws_helpers.sh
aws_local s3 mb s3://mission-bucket >/dev/null 2>&1 || true
aws_local s3api put-bucket-policy   --bucket mission-bucket   --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::mission-bucket/*"}]}' >/dev/null
aws_local s3api put-public-access-block   --bucket mission-bucket   --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
echo "Broken bucket created: mission-bucket (public access block prevents public policy)"
