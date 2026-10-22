# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Authentication for people

## Scenario

The ops team keeps its members in the Keycloak group `ops`, in the realm `inventory` at `http://keycloak.localtest.me:8080`. OpenBao should give the policy `ops` to members of that group, and to nobody else. The auth method `oidc/` is enabled in OpenBao, but it is not configured. Keycloak's client for OpenBao is `openbao`, with the secret `openbao-client-secret`, and its ID tokens carry the user's groups in the claim `groups`.

## Your task

1. Configure the auth method at `auth/oidc/` from the realm's discovery document, with the client `openbao` and its secret.
2. Create a JWT role named `ops` (`role_type` `jwt`) that:
   - accepts only ID tokens made for the client `openbao`;
   - names the user by the claim `preferred_username`;
   - reads groups from the claim `groups`;
   - accepts only members of the group `ops`;
   - gives the policy `ops`, with a token TTL of 1 hour.

## Constraints

- Do not leave `bound_audiences` empty, and do not accept any group other than `ops`.
- Do not change the policies or anything in Keycloak.

## Done when

- An ID token for `alice` (group `ops`) logs in with the role `ops` and gets the policy `ops`.
- An ID token for `bob` (group `dev`) is refused by the role `ops`.
- The role's `bound_audiences` is exactly `openbao`, and its `bound_claims` require the group `ops`.

The grader gets ID tokens from Keycloak with the password grant, which the client `openbao` allows in this lab only.
