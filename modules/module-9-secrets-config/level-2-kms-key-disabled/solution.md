# Solution

The clean-up script disabled the key behind `alias/marigold-tokens`. Ciphertext is bound to the key that produced it, so the only fix is to enable that key again.

```bash
aws kms describe-key --key-id alias/marigold-tokens      # KeyState: Disabled
aws kms enable-key --key-id <KeyId>
```

`check` decrypts the three stored tokens and compares them with their original values.
