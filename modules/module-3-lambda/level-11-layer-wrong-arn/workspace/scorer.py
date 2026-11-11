"""Ironbridge Pay: transaction risk scorer.

Business rules live in the shared `riskkit` layer (so the fraud team can ship
rule changes without touching this package) and request tracing in the
`tracekit` layer. This function only wires them together.
"""
import tracekit
from riskkit.rules import score, velocity_penalty


def handler(event, context):
    txn = event["txn"]
    points = score(txn)
    return {
        "score": points,
        "velocity_penalty": velocity_penalty(txn["txns_last_hour"]),
        "decision": "review" if points >= 70 else "approve",
        "trace": tracekit.trace_id(txn),
    }
