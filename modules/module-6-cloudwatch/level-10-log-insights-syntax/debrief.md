# Debrief: an empty result is not an error

Logs Insights returns zero rows both when nothing matches and when you asked about something that does not exist. A mistyped group, a field name in the wrong case or a filter on a field that is not in the data all look like "no errors". That is why a dashboard widget that quietly shows nothing is dangerous.

**How Insights sees your data**
- For JSON logs, each top-level key becomes a field you can use directly (`level`, `code`). Names are case-sensitive: `Level` is a different, empty field.
- Everything else is reachable through the built-in fields: `@message`, `@timestamp`, `@logStream`, `@log`.
- Typical query shape: `fields ... | filter ... | sort @timestamp desc | limit N`; add `stats count(*) by bin(5m)` for trends and `parse` to extract values from plain text. (The local emulator runs only a subset of the language; real AWS supports much more.)
- A dashboard widget stores the group inside the query text: `SOURCE '<group>' | ...`. Renaming a group silently breaks every widget that points at it.

**In real life**
- Run a widget's query in the Logs Insights console first, with a time range that you know contains data.
- Keep logs structured and keep field names consistent across services (`level`, not `Level` in one and `severity` in another).
- Put a "total events" widget next to an "errors" widget: if both are zero, the problem is the query or the log pipeline, not your service.
- Save queries and widgets in code, and review the `SOURCE` line when log groups are renamed.
