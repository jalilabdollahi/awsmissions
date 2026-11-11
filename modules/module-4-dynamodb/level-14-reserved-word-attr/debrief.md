# Debrief: names in expressions are parsed, not just strings

DynamoDB expressions (`UpdateExpression`, `ConditionExpression`, `FilterExpression`, `ProjectionExpression`, `KeyConditionExpression`) have their own grammar, and roughly 570 words are reserved: `status`, `name`, `comment`, `timestamp`, `size`, `data`, `date`, `year`, `count`, `user`, `type`, `order`, `group` and many more. Using one bare produces `Attribute name is a reserved keyword; reserved word: status`.

The remedy is **expression attribute names**: write `#st` in the expression and supply `{"#st":"status"}`. Rules to remember:
- placeholders start with `#`, values start with `:`; every placeholder you declare must be used (and vice versa), otherwise DynamoDB rejects the request;
- dots and dashes in attribute names also need a placeholder (`#a.#b` for nested paths, one placeholder per path element);
- do not "fix" this by renaming attributes in the data: other readers depend on them. Do not store `#st` either: if the mapping is missing the expression fails, but if you build the item with put-item and the wrong key you silently create a new attribute.

Habits that save pain:
- Wrap every attribute in a placeholder in generated code, always. The list of reserved words grows over time.
- The same words are rejected in the key-condition expression, so a good key name (avoid `name`, `status`, `type`) saves the headache everywhere.
- SDK document clients (JavaScript `lib-dynamodb`, Python `boto3.dynamodb.conditions`) generate placeholders for you.
- Emulators and real AWS can differ in how strictly they check reserved words in some expression kinds. Always escape; it never hurts.
