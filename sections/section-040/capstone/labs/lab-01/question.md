# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Identity

## Scenario

The platform team wants three things: every person is one entity, members of the Keycloak group `ops` get the policy `ops-admin` through the external group `ops-external`, and every person can write only their own folder `secret/users/<name>/` through the templated policy `personal`. None of it works:

- alice has the entity `alice` with her userpass alias, but her first JWT login (role `person` on `oidc/`) created a second entity.
- The external group `ops-external` never gets any members.
- alice cannot write `secret/users/alice/...`.

The ID of the entity `alice` is in the ConfigMap `capstone-baseline` in the namespace `clients`.

## Your task

1. Make both of alice's logins return the entity `alice`, keeping that entity's ID.
2. Make members of the Keycloak group `ops` join `ops-external` when they log in with JWT.
3. Fix the policy `personal` so a person can create, read and update `secret/users/<their entity name>/*` and nothing of other people's.

## Constraints

- Do not delete or recreate the entity `alice`.
- Keep `ops-external` an external group, and do not add members to it by hand.
- Keep `personal` a policy template; do not write a policy that names alice.

## Done when

- A userpass login and a JWT login as alice both return the original entity ID of `alice`.
- alice's JWT token carries `ops-admin` in its identity policies, and bob's does not.
- alice can write `secret/users/alice/...` and is refused `secret/users/bob/note`.
