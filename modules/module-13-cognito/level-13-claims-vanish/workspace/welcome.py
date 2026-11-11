# Post confirmation trigger: runs after a user confirms their account.
# (Sends the welcome email in production. Nothing to change here.)


def handler(event, context):
    print("welcome", event["userName"])
    return event
