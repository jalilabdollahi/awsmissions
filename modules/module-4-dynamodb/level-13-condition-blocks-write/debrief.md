# Debrief: a condition has to describe the state you expect

`ConditionExpression` makes a write atomic with a check: DynamoDB evaluates the condition against the **current** item and applies the write only if it is true; otherwise it fails with `ConditionalCheckFailedException` and changes nothing. There is no read-then-write race because the check and the write are one operation.

Three patterns cover most uses:
1. **Create-only:** `attribute_not_exists(pk)`. Protects against overwriting an item that is already there. Perfect for "insert", wrong for "update", which is exactly what this script mixed up.
2. **State machine guard:** `#status = :expected`. Allows a transition only from the right state (PACKED to SHIPPED, never SHIPPED to SHIPPED).
3. **Optimistic locking:** keep a `version` number, read it, write with `version = :seen` and `ADD version 1`. Two concurrent writers cannot both win; the loser gets the exception and retries with fresh data.

The tempting fix is to delete the condition. It makes the error go away and silently re-ships ord-1043. A failed condition is not a bug to silence; it is DynamoDB telling you the world is not how your code assumed.

Practical notes:
- Treat `ConditionalCheckFailedException` as a normal outcome in application code (reload and decide), not as an alarm.
- Use `--return-values-on-condition-check-failure ALL_OLD` to see what blocked the write.
- Conditions on a single item are cheap; across items use `TransactWriteItems` with a `ConditionCheck`.
- `status` is a reserved word, so the expression needs `#s` with `ExpressionAttributeNames`. See the next problem on reserved words.
