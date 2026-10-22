# Entities And Aliases

Log in twice as the same person through two auth methods, and OpenBao may record two different people. This part shows where that record lives, why OpenBao creates it on its own, and how to join two logins into one entity so OpenBao knows they are the same person.

## Every login has an entity

When a login succeeds, OpenBao looks for an **alias**: a record that says "the account `alice` on this auth mount belongs to this entity". An alias is keyed by the account name and the **mount accessor**, an ID OpenBao gives each auth mount. If no alias exists, OpenBao creates a new **entity** with a generated name and an alias for this login. The token's `entity_id` points at that entity.

See it happen. Log in once with userpass and once with a JWT from Keycloak, and compare the two entity IDs:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
alice_id_token() {
  curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username=alice -d password=alice-password -d scope=openid | jq -r .id_token
}
bao write -format=json auth/userpass/login/alice password=alice-password | jq -r .auth.entity_id
bao write -format=json auth/oidc/login role=person jwt=$(alice_id_token) | jq -r .auth.entity_id
```

The two IDs differ. To OpenBao, alice is two people: one with a userpass alias, one with an alias on `oidc/`. (The password grant in `alice_id_token` is a lab shortcut; a real person logs in through the browser.)

## Look at the entities

`identity/entity/id` lists every entity. Read one to see its aliases:

```sh
bao list identity/entity/id
bao auth list
```

Each entity's name is generated, such as `entity-` followed by a random ID. `bao auth list` shows the accessor of each auth mount, for example `auth_userpass_` followed by a short ID. Reading an entity with `bao read identity/entity/id/<id>` shows its `aliases`, each with a `name` (`alice`) and a `mount_accessor`. For a JWT login, the alias name is the value of the role's `user_claim`, here the user name `alice`.

## Join two logins into one entity

The clean way is to create the entity and its aliases before the person logs in for the first time. Here alice has already logged in, so her logins have two entities. **Merging** moves the aliases and group memberships of one or more entities into another, and deletes the ones merged from. Create a named entity for alice, then merge both generated entities into it:

```sh
bao write identity/entity name=alice metadata=team=ops
ALICE_ENTITY_ID=$(bao read -field=id identity/entity/name/alice)
USERPASS_ACCESSOR=$(bao auth list -format=json | jq -r '."userpass/".accessor')
OIDC_ACCESSOR=$(bao auth list -format=json | jq -r '."oidc/".accessor')
UP_ENTITY=$(bao write -format=json identity/lookup/entity alias_name=alice alias_mount_accessor=$USERPASS_ACCESSOR | jq -r .data.id)
JWT_ENTITY=$(bao write -format=json identity/lookup/entity alias_name=alice alias_mount_accessor=$OIDC_ACCESSOR | jq -r .data.id)
bao write identity/entity/merge from_entity_ids=$UP_ENTITY,$JWT_ENTITY to_entity_id=$ALICE_ENTITY_ID
```

`identity/lookup/entity` finds the entity that holds a given alias. After the merge, run the two logins again: both return the ID of the entity `alice`. When no login has happened yet, you skip the merge and create the aliases directly with `bao write identity/entity-alias name=alice canonical_id=$ALICE_ENTITY_ID mount_accessor=$USERPASS_ACCESSOR`, and the same for the `oidc/` accessor.

An entity can hold only one alias per mount, so merging two entities that both have an alias on the same mount fails unless you say which alias to keep. You now know how every login finds its entity and how to make two logins land on the same one. Next is giving that entity policies through groups.

## Common pitfalls

> [!WARNING]
> - **Letting people log in before their entities exist.** Every first login creates a new entity. Create entities and aliases first, or plan a merge.
> - **Using the mount path instead of the accessor.** Aliases are keyed by `mount_accessor`, not by `userpass/`. Read it from `bao auth list`.
> - **Alias names that differ between methods.** The JWT alias name is the `user_claim` value. If the userpass user is `alice` but Keycloak says `alice.smith`, the aliases still work, but nothing joins them by name.
> - **Deleting and recreating an entity.** Its ID changes, so every group and template that pointed at the old ID breaks. Merge instead.
