# Solution

Both versions exist, but the labels are swapped: `AWSCURRENT` sits on the retired key and `AWSPREVIOUS` on the fresh one.

1. Inspect the labels and values:

```bash
aws secretsmanager list-secret-version-ids --secret-id sable/cdn/signing-key --include-deprecated
aws secretsmanager get-secret-value --secret-id sable/cdn/signing-key --version-id <VersionId>
```

2. Move `AWSCURRENT` back to the newer version:

```bash
aws secretsmanager update-secret-version-stage --secret-id sable/cdn/signing-key \
  --version-stage AWSCURRENT \
  --move-to-version-id <newer VersionId> \
  --remove-from-version-id <older VersionId>
```

3. `check` reads the default value (must be the fresh key) and the `AWSPREVIOUS` value (must still be the retired key).
