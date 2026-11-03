# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** LDAP authentication

## Scenario

The company directory runs OpenLDAP at `ldap://openldap.ldap.svc.cluster.local:389` for `dc=example,dc=org`. People are stored under `ou=people` and log in with their `uid`. Groups are stored under `ou=groups`. You are asked to let the engineers read the inventory secrets and the auditors read the reports, using the directory groups, without creating any user in OpenBao.

## Your task

1. Enable the LDAP auth method at `ldap/` and configure it with:
   - the search account `cn=readonly,dc=example,dc=org` and its password `readonly-password`;
   - users below `ou=people,dc=example,dc=org`, found by the attribute `uid`;
   - groups below `ou=groups,dc=example,dc=org`, named by the attribute `cn`.
2. Map the group `engineers` to the policy `inventory-read` and the group `auditors` to the policy `reporting`.

## Constraints

- Do not use the directory administrator account (`cn=admin,...`) as the search account.
- Do not map any user by name. Use the group mappings only.
- Keep `deny_null_bind` at its default value.
- Do not change the policies `inventory-read` and `reporting`.

## Done when

- Alice (password `alice-password`) logs in with `inventory-read`, reads `secret/inventory/db` and is refused `secret/reports/q3`.
- Bob (password `bob-password`) logs in with `reporting`, reads `secret/reports/q3` and is refused `secret/inventory/db`.
- Carol (password `carol-password`), who is in no group, logs in with only the `default` policy.
- A wrong password and an empty password are refused.
