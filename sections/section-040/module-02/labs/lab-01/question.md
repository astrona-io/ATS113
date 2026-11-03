# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Entities and identity tokens

## Scenario

The inventory service wants to know who calls it, and which team the caller is on, without holding an OpenBao token. You will issue signed identity tokens for the people of the inventory team. Alice already has a userpass account (password `alice-password`) with the policy `identity-reader`, which lets her read identity tokens. An entity `alice` exists with an alias for that login, but it has no metadata.

## Your task

1. Give the entity `alice` the metadata `team=inventory`. Keep its alias.
2. Create the identity token key `inventory` with the algorithm `RS256`, a rotation period of 24 hours, a verification period of 24 hours, and `allowed_client_ids` set to `*`.
3. Create the identity token role `inventory-reader` on that key, with a lifetime of 30 minutes and a template that sets two claims: `team` from the entity metadata `team`, and `name` from the entity name.

## Constraints

- Do not change the userpass user or the policy `identity-reader`.
- Do not set the reserved claims `iss`, `sub`, `aud`, `exp`, `nbf` or `iat` in the template.
- Do not create a second entity for alice.

## Done when

- Alice logs in with userpass and reads a token from `identity/oidc/token/inventory-reader`.
- The decoded token has the claims `team` as `inventory` and `name` as `alice`, its subject is the ID of the entity `alice`, and it expires 30 minutes after it was issued.
- Introspection reports the token as active.
