# Join Logins Into One Identity

alice is in the ops team. She logs in through Keycloak most days and with a local userpass account during outages. If her two logins are two strangers to OpenBao, every policy must be granted twice, and nothing can say "alice's own secrets". The identity system fixes that by joining her logins into one record, the entity, and letting groups and policies refer to it.

An **entity** is one person or machine in OpenBao's identity store. An **alias** links an entity to its account in one auth method. A **group** gives policies to many entities at once. OpenBao keeps all three under the path `identity/`.

The module has three parts. **Entities And Aliases** shows how every login maps to an entity, how OpenBao creates entities by itself, and how to join two logins into one. **Internal And External Groups** shows groups whose members you set and groups whose members come from Keycloak; a graded lab follows it. **Identity In Policy Templates** writes one policy that gives every person their own folder.

## Learning objectives

After this module you can:

- Find the entity behind a login from the token's `entity_id`.
- Create an entity and aliases on two auth mounts, keyed by their mount accessors.
- Merge two entities that belong to the same person.
- Create internal groups and external groups with group aliases.
- Tell token policies from identity policies in a token lookup.
- Write a policy template with `{{identity.entity.name}}`.

## Before you start

You should know what a token and a policy are, and how userpass and JWT logins work. You do not need to configure Keycloak; it is ready.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed, and **Keycloak 26.8.1**. It holds:

| Object | What it is |
| --- | --- |
| Userpass user `alice` | Password `alice-password` (lab-only) |
| Auth method `oidc/`, role `person` | A JWT role for Keycloak's realm `inventory`, `user_claim` `preferred_username`, `groups_claim` `groups` |
| Keycloak users | `alice` in the group `ops`, `bob` in the group `dev` |
| Policies `ops`, `ops-shared` | Read `secret/data/ops/*` |
| KV engine `secret/` | Includes `secret/users/alice/note` and `secret/users/bob/note` |

Start two port-forwards in a second terminal, one for OpenBao and one for Keycloak:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
