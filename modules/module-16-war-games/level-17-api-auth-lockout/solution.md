# Solution

1. **Authorization type.** The migration script made `GET /lockers` `AWS_IAM`; partners send a token, not a SigV4 signature. Change the method to `CUSTOM` with the existing authorizer (`update-method` with a patch for `/authorizationType` and `/authorizerId`). Setting it to `NONE` would remove authentication and is rejected.
2. **Identity source.** The authorizer was copied from the admin API and reads `X-Admin-Token`. Change it to `method.request.header.Authorization` (`update-authorizer`).
3. **Authorizer role.** `pl-auth-role` cannot call `ssm:GetParameter`, so the authorizer throws before it can compare tokens. Allow it on `parameter/pelican/partner-token`.
4. **Backend role.** `pl-lockers-role` only has `dynamodb:GetItem`; the function scans. Add `dynamodb:Scan` on the `pl-lockers` table.
5. **Deploy.** `aws apigateway create-deployment --rest-api-id <api> --stage-name live`, so the `live` stage serves the corrected definition.

`check` examines the method and authorizer, invokes both Lambdas directly with realistic events (including a wrong token), then makes the real partner request, plus a request without a token and one with a wrong token, which must both be rejected.
