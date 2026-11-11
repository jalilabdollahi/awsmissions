# Solution

`status`, `comment` and `timestamp` are on DynamoDB's reserved word list, so they cannot appear as bare names in an expression. Substitute each with a `#placeholder` and define the mapping in `--expression-attribute-names`. Values keep their `:` placeholders.

In `close-ticket.sh`:

```bash
--update-expression "SET #st = :closed, #co = :note, #ts = :now" \
--expression-attribute-names '{"#st":"status","#co":"comment","#ts":"timestamp"}' \
```

Then run:

```bash
./close-ticket.sh tk-77 "Refund issued to original card"
```

The attributes keep their real names in the table; placeholders exist only inside the request.
