"""Cobalt Parcel: shipping label formatter.

The nightly dispatch job sends one shipment per invocation and prints whatever
comes back onto the thermal label.
"""

SERVICE_CODES = {"ground": "GR", "air": "AR", "express": "XP"}


def build_label(event, context):
    city = str(event["city"]).strip().upper()
    state = str(event["state"]).strip().upper()
    postcode = str(event["zip"]).strip()
    service = SERVICE_CODES.get(str(event.get("service", "ground")).lower(), "GR")
    weight = float(event["weight_kg"])

    return {
        "label": f"{city}, {state} {postcode} | {service} | {weight:.1f}KG",
        "needs_signature": weight > 20 or service == "express",
    }
