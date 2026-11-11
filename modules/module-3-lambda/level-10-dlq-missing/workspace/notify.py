"""Relaycast: SMS notifier.

Invoked asynchronously by the order service ("fire and forget"). Sending an
SMS is not idempotent: a repeated attempt sends the customer a second text.
"""
import re

E164 = re.compile(r"^\+[1-9]\d{7,14}$")


def send(event, context):
    number = event.get("to", "")
    if not E164.match(number):
        raise ValueError(f"invalid destination number: {number!r}")
    # The real provider call lives here.
    return {"id": event["id"], "to": number, "status": "queued-with-provider"}
