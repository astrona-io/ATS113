# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Identity

## Scenario

alice logs in to OpenBao in two ways: with the userpass account `alice` (password `alice-password`) and through Keycloak, with the JWT role `person` on the auth mount `oidc/`. The ops team wants her, and everyone in the team, to get the policy `ops-shared` no matter how they log in. Nobody has logged in yet, so no entities exist.

## Your task

1. Create an entity named `alice` with the metadata `team=ops`.
2. Give it two aliases named `alice`: one on the `userpass/` mount and one on the `oidc/` mount.
3. Create an **internal** group named `ops` with the policy `ops-shared`, and make the entity `alice` a member.

## Constraints

- Do not add `ops-shared` to the userpass user or to the role `person`; it must come from the group.
- Do not change the auth methods or the policies.

## Done when

- The entity `alice` has an alias `alice` on `userpass/` and one on `oidc/`.
- A userpass login and a JWT login as alice both return the ID of the entity `alice`.
- The internal group `ops` contains alice, and her token carries `ops-shared` in its identity policies.

The grader gets alice's ID token from Keycloak with the password grant, which the client `openbao` allows in this lab only.
