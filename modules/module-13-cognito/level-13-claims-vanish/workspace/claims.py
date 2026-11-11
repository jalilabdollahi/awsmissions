# Pre token generation trigger for the cobalt-tenants user pool.
#
# Every API behind the gateway isolates data by the "tenant" claim of the ID
# token, so each user's tenant (stored in the custom attribute custom:tenant)
# has to be copied into the token when it is issued.


def handler(event, context):
    attrs = event["request"]["userAttributes"]
    tenant = attrs.get("custom:tenant_id")

    claims = {}
    if tenant:
        claims["tenant"] = tenant

    event["response"] = {
        "claimsOverrideDetails": {"claimsToAddOrOverride": claims}
    }
    return event
