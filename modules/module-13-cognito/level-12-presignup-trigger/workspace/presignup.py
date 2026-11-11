# Pre sign-up trigger for the brightpath-partners user pool.
#
# Staff of our partner agencies should not have to wait for an email code:
# when the sign-up address belongs to a partner domain the account is
# confirmed and the address marked as verified. Everybody else goes through
# the normal confirmation flow.

PARTNER_DOMAINS = ["partner.example.com", "agency.example.org"]


def handler(event, context):
    email = event["request"]["userAttributes"]["email"]
    domain = email.split("@")[1]

    if domain in PARTNER_DOMAINS:
        event["response"]["autoConfirmUser"] = True
        event["response"]["autoVerifyEmail"] = True
        return

    return event
