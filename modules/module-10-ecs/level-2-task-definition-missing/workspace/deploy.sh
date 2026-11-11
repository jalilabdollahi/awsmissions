#!/usr/bin/env bash
# Harbor Freight Tracker: create the frontend service.
aws ecs create-service \
  --cluster harbor \
  --service-name harbor-web \
  --task-definition harbor-web:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-a,subnet-default-us-east-1-b],assignPublicIp=ENABLED}"
