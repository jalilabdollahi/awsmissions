#!/usr/bin/env bash
# Launch the Hearthstone Pantry storefront (latest ACTIVE revision of hearth-web).
aws ecs run-task \
  --cluster hearth \
  --task-definition hearth-web \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-default-us-east-1-c],assignPublicIp=ENABLED}"
