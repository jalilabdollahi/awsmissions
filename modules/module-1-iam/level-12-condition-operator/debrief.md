# Debrief: operators decide how values are compared

Condition operators come in families, and picking the wrong one is as bad as picking the wrong key:

| Operator | Compares |
|---|---|
| `StringEquals` / `StringNotEquals` | exact text (case-sensitive), no wildcards |
| `StringLike` / `StringNotLike` | text with `*` and `?` wildcards |
| `ArnLike` / `ArnEquals` | ARNs, segment aware |
| `IpAddress` | CIDR ranges |
| `Bool`, `Null`, `NumericLessThan`, `DateGreaterThan` | booleans, presence, numbers, dates |

Add `IfExists` (`StringEqualsIfExists`) to make a missing key count as a match, and `ForAnyValue:` / `ForAllValues:` to compare multi-valued keys.

For S3 listing the story is subtle: `s3:ListBucket` is a bucket-level action, so it cannot be limited by object ARN. The only way to say "only below this folder" is the `s3:prefix` condition, and a listing without any prefix does not match `matters/2025/*`, so the bucket root stays closed.

**In real life**
- A wildcard in a value only works with a `...Like` operator. Treat any `*` in a `StringEquals` value as a bug.
- Pair the list condition with an object-level `Resource` ARN for `GetObject` so reading is also confined to the prefix, as in this policy.
- Folder-based access in the console also needs `s3:ListBucket` with `s3:delimiter`; test with the same calls your users make.
