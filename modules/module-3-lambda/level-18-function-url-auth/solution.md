# Solution

A function URL has three independent controls here: how callers authenticate (`AuthType`), whether a public principal is *allowed* to use it (resource policy) and which browser origins may call it (CORS, already correct here). The template left authentication on the strictest setting.

1. Inspect the URL configurations:

```bash
aws lambda get-function-url-config --function-name invite-landing
aws lambda get-policy --function-name invite-landing      # no policy yet
```

2. Switch the public function to unauthenticated access. The CORS settings (already limited to the sign-up origin) stay untouched, so update the existing URL instead of recreating it:

```bash
aws lambda update-function-url-config --function-name invite-landing --auth-type NONE
```

3. `NONE` only means "no signature required". You must also let everybody invoke through the URL in the function's resource policy:

```bash
aws lambda add-permission --function-name invite-landing \
  --statement-id public-url-access \
  --action lambda:InvokeFunctionUrl \
  --principal '*' --function-url-auth-type NONE
```

4. Leave `invite-admin` alone; it keeps `AWS_IAM`.
