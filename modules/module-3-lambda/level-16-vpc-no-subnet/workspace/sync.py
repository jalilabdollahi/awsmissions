"""Orbit Retail: order sync.

Copies new storefront orders into the orders database. The database sits in a
private subnet of the orders VPC and has no public endpoint, so this function
has to run inside that VPC to reach it.
"""
import os


def run(event, context):
    host = os.environ["ORDERS_DB_HOST"]
    orders = event.get("orders", [])
    # The real client opens a TCP connection to host:5432 here.
    return {"db": host, "synced": len(orders)}
