# Solution

1. **IAM policy.** `claims-secrets` allowed `GetSecretValue` on the *old* ARN (`...:secret:juniper/prod/db-credentials-<oldsuffix>`). Re-creating the secret generated a new suffix. Allow `arn:aws:secretsmanager:us-east-1:000000000000:secret:juniper/prod/db-credentials-*` instead: tied to the name, valid across re-creations, and still limited to this one secret. `Resource: "*"` would also expose the billing key.
2. **Lambda configuration.** `SECRET_ID` holds the old ARN. Set it to the new ARN from `describe-secret` (the secret's name also works).
3. **Version stage.** The failed rotation left the new password under `AWSPENDING`. Find both version ids with `describe-secret` and run `update-secret-version-stage --version-stage AWSCURRENT --move-to-version-id <pending> --remove-from-version-id <current>`.

`check` assumes the role to read the secret (and to confirm it cannot read the billing key), verifies the function's identifier resolves, compares the `AWSCURRENT` password with the database's, and invokes the function.
