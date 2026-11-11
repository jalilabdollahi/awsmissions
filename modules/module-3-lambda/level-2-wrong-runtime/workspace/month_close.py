"""Harborline Ledger: month-end close aggregator.

Receives the journal entries of one account and returns the totals the
finance dashboard shows. Written for the current Python release line.
"""
from dataclasses import dataclass


@dataclass
class Entry:
    account: str
    amount_cents: int
    kind: str


def classify(entry: Entry) -> tuple[str, int]:
    match entry:
        case Entry(kind="credit", amount_cents=cents) if cents > 0:
            return "credit", cents
        case Entry(kind="debit", amount_cents=cents) if cents > 0:
            return "debit", cents
        case Entry(kind="void"):
            return "void", 0
        case _:
            raise ValueError(f"unusable entry for {entry.account}")


def handler(event, context):
    credits = debits = voids = 0
    for raw in event["entries"]:
        kind, cents = classify(Entry(**raw))
        if kind == "credit":
            credits += cents
        elif kind == "debit":
            debits += cents
        else:
            voids += 1
    return {"credits": credits, "debits": debits, "net": credits - debits, "voided": voids}
