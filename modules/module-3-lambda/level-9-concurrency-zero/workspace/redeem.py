"""Brightside Coupons: coupon redemption.

Every redemption takes a connection from the shared Postgres pool, which only
has room for 25 connections in total (5 are kept for the admin tools).
"""
import re

CODE = re.compile(r"^BRT-(?P<pct>\d{2})-(?P<tail>[A-Z0-9]{6})$")


def redeem(event, context):
    match = CODE.match(event.get("code", ""))
    if not match:
        return {"valid": False, "reason": "malformed code"}
    pct = int(match.group("pct"))
    if pct > 50:
        return {"valid": False, "reason": "discount above policy"}
    price = float(event["cart_total"])
    return {"valid": True, "discount_pct": pct, "new_total": round(price * (100 - pct) / 100, 2)}
