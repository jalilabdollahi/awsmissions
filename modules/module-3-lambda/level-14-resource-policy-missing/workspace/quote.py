"""Cartwheel Logistics: freight rate quote engine.

Partners call this directly (no API in front) to price a pallet shipment.
"""
RATE_PER_KM = {"standard": 0.42, "refrigerated": 0.71}


def quote(event, context):
    mode = event.get("mode", "standard")
    price = RATE_PER_KM[mode] * float(event["km"]) * max(1, int(event["pallets"]))
    return {"mode": mode, "price_eur": round(price, 2)}
