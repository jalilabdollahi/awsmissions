# Solution

```bash
TMPDIR="$(mktemp -d)"
cat > "$TMPDIR/index.py" <<'EOF'
import json

def lambda_handler(event, context):
    return {"statusCode": 200, "body": json.dumps("ok")}
EOF
(
  cd "$TMPDIR"
  python3 - <<'EOF'
import zipfile
with zipfile.ZipFile('function.zip', 'w') as z:
    z.write('index.py')
EOF
)

aws lambda create-function   --function-name mission-function   --runtime python3.11   --role arn:aws:iam::000000000000:role/mission-lambda-role   --handler index.lambda_handler   --zip-file fileb://"$TMPDIR/function.zip"

rm -rf "$TMPDIR"
```
