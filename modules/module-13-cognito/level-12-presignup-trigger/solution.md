# Solution

A Cognito Lambda trigger must **return the event it received**, with `response` modified. The partner branch of `presignup.py` sets the right flags and then does a bare `return`, so Cognito receives nothing back and reports an invalid Lambda response. A second bug sits next to it: the domain comparison is case-sensitive, so `Partner.Example.COM` never matches `partner.example.com`.

1. Reproduce and read the error:

```bash
aws cognito-idp list-user-pools --max-results 10
aws cognito-idp list-user-pool-clients --user-pool-id <pool-id>
aws cognito-idp sign-up --client-id <client-id> --username t1 --password 'Onboard-Me-2024!' \
  --user-attributes Name=email,Value=t1@partner.example.com
```

2. Edit `presignup.py` (`edit`):

```python
domain = email.split("@")[1].lower()
...
    if domain in PARTNER_DOMAINS:
        event["response"]["autoConfirmUser"] = True
        event["response"]["autoVerifyEmail"] = True
        return event
```

3. Package it and update the function:

```bash
zip function.zip presignup.py
aws lambda update-function-code --function-name brightpath-presignup --zip-file fileb://function.zip
```

4. Run `check`. It signs up partner users (lower-case, mixed-case, the second domain) and ordinary users, plus one lookalike domain, and looks at the real outcome each time.
