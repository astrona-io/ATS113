# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Authentication for people

## Scenario

Since a configuration change yesterday, nobody from the ops team can log in to OpenBao through Keycloak. The on-call engineer tried the break-glass userpass account `breakglass` (password `breakglass-password`) instead, but it has no useful policy. You are asked to repair both.

The setup is meant to be: the auth method `oidc/` trusts the realm `inventory` at `http://keycloak.localtest.me:8080`, with the client `openbao` (secret `openbao-client-secret`). The JWT role `ops` gives the policy `ops` to members of the Keycloak group `ops`, whose ID tokens carry the groups in the claim `groups`. The break-glass account should have the policy `breakglass`.

## Your task

1. Find and fix every setting that stops `alice` (group `ops`) from logging in with the role `ops`.
2. Give the userpass account `breakglass` the policy `breakglass`, without changing its password.

## Constraints

- The role `ops` must still accept only ID tokens made for the client `openbao`, and only members of the group `ops`.
- Do not create new auth mounts or roles; repair the ones that exist.
- Do not change anything in Keycloak.

## Done when

- alice logs in with the role `ops` and gets the policy `ops`.
- bob (group `dev`) is still refused.
- `breakglass` logs in with the password `breakglass-password` and gets the policy `breakglass`.
