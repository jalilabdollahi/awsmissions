"""Pebble Studio: invite landing endpoint.

Called straight from the browser by the public sign-up page, through the
function's own HTTPS URL (payload format 2.0).
"""
import json


def handle(event, context):
    method = event["requestContext"]["http"]["method"]
    if method != "POST":
        return {"statusCode": 405, "body": json.dumps({"error": "POST only"})}
    try:
        email = json.loads(event.get("body") or "{}")["email"]
    except (ValueError, KeyError):
        return {"statusCode": 400, "body": json.dumps({"error": "email required"})}
    return {
        "statusCode": 201,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"invited": email}),
    }
