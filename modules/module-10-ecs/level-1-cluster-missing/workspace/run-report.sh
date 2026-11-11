#!/usr/bin/env bash
# Nightly job launcher (Ledgerly finance). Called by cron at 02:00.
aws ecs run-task \
  --cluster ledgerly-batch \
  --task-definition nightly-report \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a],assignPublicIp=ENABLED}"
