# Solution

A Firehose transformation Lambda must return `{"records": [...]}` with **one entry per input record**, each carrying:

- `recordId`: the same id Firehose sent (it matches output to input);
- `result`: exactly `Ok`, `Dropped` or `ProcessingFailed`;
- `data`: the new payload, **base64-encoded**.

`shaper.py` breaks all of it: it invents a new `recordId`, answers `Success`, returns plain JSON text, forgets the trailing newline (Firehose just concatenates records), and lets a missing `fare_cents` raise a `KeyError`, which fails the whole batch.

1. Find out what Firehose says about the failures. Records it could not transform are stored under `ride-rejects/` with an `errorCode` and `errorMessage`:

```bash
aws s3 ls s3://swiftcab-lake/ --recursive
```

2. Rewrite `shaper.py` (`edit`) so each record is handled on its own:

```python
try:
    ride = json.loads(base64.b64decode(rec["data"]))
    shaped = {...}
    payload = (json.dumps(shaped) + "\n").encode("utf-8")
    out.append({"recordId": rec["recordId"], "result": "Ok",
                "data": base64.b64encode(payload).decode("ascii")})
except (KeyError, ValueError, TypeError):
    out.append({"recordId": rec["recordId"], "result": "ProcessingFailed", "data": rec["data"]})
```

3. Deploy:

```bash
zip shaper.zip shaper.py
aws lambda update-function-code --function-name ride-event-shaper --zip-file fileb://shaper.zip
```

4. `check` first calls the function directly with a good, a good and a bad record and inspects the response, then sends three real events through Firehose and reads the lake.
