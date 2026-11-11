# Solution

Reserved concurrency of `0` means "this function may run zero copies at once": every invocation is throttled. It was set deliberately during the incident and never lifted. Removing it entirely would also work for traffic, but the post-mortem wants the cap kept, at 20 or lower.

1. Inspect the setting:

```bash
aws lambda get-function-concurrency --function-name coupon-redeemer
```

2. Replace it with the real limit of the database pool:

```bash
aws lambda put-function-concurrency --function-name coupon-redeemer \
  --reserved-concurrent-executions 20
```

3. Invoke the function with a coupon such as `{"code":"BRT-15-K7Q2ZD","cart_total":80}`; the new total should be 68.
