# Solution

```bash
LAYER_ARN="$(aws lambda list-layer-versions   --layer-name mission-utils   --query 'LayerVersions[0].LayerVersionArn'   --output text)"

aws lambda update-function-configuration   --function-name mission-function   --layers "$LAYER_ARN"
```
