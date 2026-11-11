# Solution

The alias `alias/lanternfish-vault` was never created, and an alias cannot exist without a key behind it.

```bash
# 1. Create a symmetric encryption key (the default key type)
aws kms create-key --description "Lanternfish document vault"

# 2. Give it the name the vault expects
aws kms create-alias --alias-name alias/lanternfish-vault --target-key-id <KeyId>

# 3. Satisfy the rotation requirement
aws kms enable-key-rotation --key-id <KeyId>
```

`check` resolves the alias, verifies the key is a customer-managed, enabled, symmetric ENCRYPT_DECRYPT key with rotation on, and then encrypts and decrypts a string through the alias.
