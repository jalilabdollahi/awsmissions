# Debrief: a trigger is a function with a contract

Cognito can call your Lambda function at fixed points of a user's life: before sign-up, after confirmation, before and after authentication, before token generation, during custom auth, and more. Each trigger gets an `event` and must return **the same event**, with the `response` section filled in as that trigger defines it. The pool then continues with whatever came back.

For **pre sign-up** the response flags are:

| Flag | Effect |
|---|---|
| `autoConfirmUser` | skip the confirmation step; the user is `CONFIRMED` immediately |
| `autoVerifyEmail` / `autoVerifyPhone` | mark the address as verified (needed for password recovery) |

Raising an exception makes the sign-up fail with `UserLambdaValidationException` and your message, which is how you *reject* a registration on purpose. Returning nothing or the wrong shape is a bug and fails with `InvalidLambdaResponseException`.

**What went wrong at Brightpath**
- The partner branch ended with a bare `return`: the function "worked" but returned `None`. Python hides this kind of mistake: no error inside the function, only on the caller's side.
- The domain check was case-sensitive. The local part of an address may be case-sensitive in theory, but the domain never is. Normalise (`.lower()`) before comparing.

**In real life**
- Match the whole domain, not a prefix or `endswith` on a bare string: `partner.example.com.evil.net` and `notpartner.example.com` are classic bypasses of "starts with" or "ends with" checks. An exact comparison against the list is the safe form.
- Trigger failures are visible to end users. Keep the error messages friendly and log details to CloudWatch.
- Cognito must be allowed to invoke the function (a resource-based permission for `cognito-idp.amazonaws.com`). The console adds it for you, the CLI does not.
- Triggers run synchronously with a 5-second timeout. Keep them quick, and avoid cold-start-heavy dependencies.
- A change to the pool's trigger list is replace-style too; see the next missions in this module.
