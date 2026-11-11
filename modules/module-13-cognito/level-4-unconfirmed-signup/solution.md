# Solution

Kai's account is `UNCONFIRMED`. Until the sign-up is confirmed, Cognito refuses to sign the user in. Confirming with the emailed code also marks the email as verified, which an administrator-side confirmation does not.

1. Check the status:

```bash
aws cognito-idp list-users --user-pool-id <pool-id> --query 'Users[].[Username,UserStatus]'
```

2. Read the verification code from the emulator's mail outbox, as the "lost" email:

```bash
curl -s "$AWS_ENDPOINT_URL/_aws/ses" | jq -r '.messages[] | [.Destination.ToAddresses[0], .Body.text_part] | @tsv'
```

3. Confirm the sign-up with that code, using the client Kai signed up through:

```bash
aws cognito-idp confirm-sign-up --client-id <client-id> --username kai --confirmation-code <code>
```

`admin-confirm-sign-up` would also let Kai in, but it leaves `email_verified` as `false`. Then the "forgot password" flow cannot send anything to Kai, so `check` insists on a verified address. (If you did go that way, `admin-update-user-attributes --user-attributes Name=email_verified,Value=true` finishes the job.)
