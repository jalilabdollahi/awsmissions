# Solution

The code does `os.environ["RATES_TABLE"]`, and the variable is not set, hence the `KeyError`. Two things make the fix more than a one-liner: the production table is one of two, and `--environment` replaces the whole set of variables.

1. See what is configured and what the code reads:

```bash
aws lambda get-function-configuration --function-name fx-rate-lookup --query Environment
grep environ fx_lookup.py
aws dynamodb list-tables
aws iam get-role-policy --role-name fx-lookup-role --policy-name read-prod-rates
```

The role may only read `maple-fx-rates-prod`.

2. Set the new variable together with the existing one:

```bash
aws lambda update-function-configuration --function-name fx-rate-lookup \
  --environment 'Variables={RATES_TABLE=maple-fx-rates-prod,FX_PRECISION=4}'
```

3. Invoke with `{"pair":"EURUSD","amount":2500}`; the answer should be `2718.3750`.
