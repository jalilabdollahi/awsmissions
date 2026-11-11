# Partner escalation PX-318 - "every call is rejected, the docs say it should work"

Pelican Parcel Lockers. Partner integrations team.

## The contract with partners (published, unchangeable)
    GET https://<api-host>/live/lockers
    Authorization: <partner token>
    ->  200  {"lockers": [...]}

- Every partner call carries its token in the standard `Authorization` header.
- The token is validated by our Lambda authorizer (`pl-token-auth`), which
  compares it with the value stored in SSM parameter `/pelican/partner-token`.
- Calls with no token or a wrong token must be rejected.
- The backend (`pl-lockers-api`) lists lockers from the DynamoDB table
  `pl-lockers`.

## What partners report
- Partner A: `403 Missing Authentication Token`-style errors.
- Partner B: after "fixing" their client to sign requests with SigV4, they get
  through the auth stage but see `502` from the backend.
- Our own smoke test (token in the `Authorization` header) gets `401`.

## Migration notes
- The API was recreated from the old definition by a script. The script's
  author "made methods IAM-authenticated by default for safety".
- The authorizer was created by copy-paste from the internal admin API, which
  uses a custom header name.
- Both Lambda roles were re-created with minimal permissions; "minimal" turned
  out to be less than needed.
- The authorizer result cache is disabled on purpose (TTL 0); do not enable it.

## Out of scope
Do not turn authentication off. A partner API without auth is a data leak.
