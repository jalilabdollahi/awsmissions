"""Quillmark Reports: customer statement renderer.

Each page of a statement is typeset one after another; a page takes roughly
600 ms. The customer portal calls this through an HTTP API, so a request must
come back within the API's 29 second limit.
"""
import time

PAGE_SECONDS = 0.6


def render(event, context):
    pages = int(event["pages"])
    done = 0
    for _ in range(pages):
        time.sleep(PAGE_SECONDS)
        done += 1
    return {
        "customer": event["customer"],
        "pages_rendered": done,
        "ms_left": context.get_remaining_time_in_millis(),
    }
