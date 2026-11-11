#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/mg-thumbnailer-role"
FN=mg-thumbnailer
stamp="$(date +%s)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
head -c 4096 /dev/zero | tr '\0' 'x' > "$tmp/img.bin"
bad=0
echo "Gallery pipeline triage"

for item in "s3api head-bucket --bucket mg-photo-uploads" "s3api head-bucket --bucket mg-photo-thumbs" "lambda get-function --function-name $FN"; do
  # shellcheck disable=SC2086
  if ! aws_local $item >/dev/null 2>&1; then
    echo "Something was deleted instead of repaired (aws $item fails)."
    exit 1
  fi
done

# Safety: the thumbnailer must not be able to write into the bucket that triggers it.
rc=0
aws_as_role "$ROLE_ARN" mg-oncall "" s3api put-object --bucket mg-photo-uploads --key loop-check.txt --body "$tmp/img.bin" >/dev/null 2>&1 || rc=$?
if [ "$rc" -eq 98 ]; then echo "mg-oncall cannot assume the thumbnailer role any more; keep the trust policy."; exit 1; fi
if [ "$rc" -eq 0 ]; then
  echo "BLOCKER: the thumbnailer role can now write to mg-photo-uploads. That is a recursive trigger waiting to happen."
  exit 1
fi

# Stage A: where does the trigger live and what does it match?
conf_up="$(aws_local s3api get-bucket-notification-configuration --bucket mg-photo-uploads --output json 2>/dev/null || echo '{}')"
[ -n "$conf_up" ] || conf_up='{}'
target="$(printf '%s' "$conf_up" | jq -r '[.LambdaFunctionConfigurations[]? | select(.LambdaFunctionArn | endswith(":mg-thumbnailer"))] | length')"
if [ "$target" = "0" ]; then
  echo "[FAULT] stage A  uploads to mg-photo-uploads do not notify the thumbnailer"
  bad=$((bad + 1))
else
  suffixes="$(printf '%s' "$conf_up" | jq -r '[.LambdaFunctionConfigurations[]? | .Filter.Key.FilterRules[]? | select(.Name | ascii_downcase == "suffix") | .Value] | join(",")')"
  case ",$suffixes," in
    *,.jpg,*|*,.JPG,*) echo "[ok]    stage A  uploads bucket notifies the thumbnailer" ;;
    *)
      echo "[FAULT] stage A  the trigger on mg-photo-uploads exists but ignores the files photographers actually upload"
      bad=$((bad + 1)) ;;
  esac
fi
conf_stg="$(aws_local s3api get-bucket-notification-configuration --bucket mg-photo-uploads-staging --output json 2>/dev/null || echo '{}')"
[ -n "$conf_stg" ] || conf_stg='{}'
if [ "$(printf '%s' "$conf_stg" | jq '[.LambdaFunctionConfigurations[]?] | length')" != "0" ]; then
  echo "[FAULT] stage A2 the staging bucket still triggers the production thumbnailer"
  bad=$((bad + 1))
else
  echo "[ok]    stage A2 staging does not trigger production"
fi

# Stage B: does the function work when it is handed a record for a real upload?
printf '%s' "$(cat "$tmp/img.bin")" > "$tmp/probe.jpg"
aws_local s3 cp "$tmp/probe.jpg" "s3://mg-photo-uploads/probe-$stamp.jpg" >/dev/null 2>&1 || true
event="{\"Records\":[{\"s3\":{\"bucket\":{\"name\":\"mg-photo-uploads\"},\"object\":{\"key\":\"probe-$stamp.jpg\"}}}]}"
aws_local lambda invoke --function-name "$FN" --cli-binary-format raw-in-base64-out --payload "$event" "$tmp/out.json" >"$tmp/meta.json" 2>&1 || true
errmsg="$(jq -r '.errorMessage // empty' "$tmp/out.json" 2>/dev/null || true)"
thumb_env="$(aws_local lambda get-function-configuration --function-name "$FN" --query 'Environment.Variables.THUMB_BUCKET' --output text 2>/dev/null || echo None)"
if printf '%s' "$errmsg" | grep -qi 'GetObject'; then
  echo "[FAULT] stage B  the function cannot read the uploaded photo: $(printf '%s' "$errmsg" | cut -c1-110)"
  bad=$((bad + 1))
else
  echo "[ok]    stage B  the function can read an upload"
fi
if ! aws_local s3api head-bucket --bucket "$thumb_env" >/dev/null 2>&1; then
  echo "[FAULT] stage C  the function is configured to write thumbnails to a bucket that does not exist"
  bad=$((bad + 1))
elif [ -z "$errmsg" ] && ! aws_local s3api head-object --bucket "$thumb_env" --key "thumb-probe-$stamp.jpg" >/dev/null 2>&1; then
  echo "[FAULT] stage C  the function ran but no thumbnail was written"
  bad=$((bad + 1))
else
  echo "[ok]    stage C  thumbnails go to an existing bucket"
fi

if [ "$bad" -gt 0 ]; then
  echo "$bad stage(s) broken. Skipping the live upload test."
  exit 1
fi

# Live test: a JPEG, a text file, and a staging JPEG.
aws_local s3 cp "$tmp/probe.jpg" "s3://mg-photo-uploads/shoot-$stamp.jpg" >/dev/null
printf 'contact sheet notes' > "$tmp/notes.txt"
aws_local s3 cp "$tmp/notes.txt" "s3://mg-photo-uploads/notes-$stamp.txt" >/dev/null
aws_local s3 cp "$tmp/probe.jpg" "s3://mg-photo-uploads-staging/qa-$stamp.jpg" >/dev/null
made() { aws_local s3api head-object --bucket mg-photo-thumbs --key "thumb-shoot-$stamp.jpg" >/dev/null 2>&1; }
if ! wait_for "thumbnail for shoot-$stamp.jpg" 45 made; then
  echo "I uploaded shoot-$stamp.jpg to mg-photo-uploads and waited 45s: no thumbnail appeared. The static checks pass, so look at what S3 actually delivers."
  exit 1
fi
sleep 5
if aws_local s3api head-object --bucket mg-photo-thumbs --key "thumb-notes-$stamp.txt" >/dev/null 2>&1; then
  echo "A .txt upload also produced a thumbnail. Only JPEGs should trigger the function."
  exit 1
fi
if aws_local s3api head-object --bucket mg-photo-thumbs --key "thumb-qa-$stamp.jpg" >/dev/null 2>&1; then
  echo "A staging upload produced a production thumbnail."
  exit 1
fi
echo "shoot-$stamp.jpg -> thumb-shoot-$stamp.jpg. Text files and staging uploads are ignored. Galleries will fill in again."
