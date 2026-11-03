# Entity Operations

An entity is a record in the identity store. This part creates entities by hand, reads them back in the ways you will need in practice, and attaches aliases and metadata. Metadata matters later, because identity tokens and policy templates read it.

## Create an entity

Create an entity with a name, metadata and policies in one write. Metadata is a set of key-value pairs, written as repeated `metadata=key=value` arguments:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao write identity/entity name=bob metadata=team=ops metadata=site=copenhagen policies=default
```

The response has the new entity's `id` and its `name`. An entity name is unique, so a second write with the same name updates the existing entity instead of creating another. The `policies` on an entity are identity policies: they apply to every token that belongs to the entity, in addition to the token's own policies.

## Read an entity

Read an entity by name or by ID. Both return the same record:

```sh
bao read identity/entity/name/bob
bao read -field=id identity/entity/name/bob
```

The record lists `metadata`, `policies`, `aliases`, `group_ids`, `disabled`, and the creation and update times. To list all entities, list by ID or by name:

```sh
bao list identity/entity/name
bao list identity/entity/id
```

Listing by name is easier to read. Listing by ID returns the IDs that every other identity call asks for.

## Look up an entity by alias

A login gives you an alias name and a mount accessor, not an entity ID. The lookup endpoint finds the entity from either:

```sh
USERPASS_ACCESSOR=$(bao auth list -format=json | jq -r '."userpass/".accessor')
bao write identity/lookup/entity alias_name=alice alias_mount_accessor=$USERPASS_ACCESSOR
bao write identity/lookup/entity name=bob
```

The first call finds the entity that owns the alias `alice` on the userpass mount. The second finds an entity by its name. Both return the entity record. A lookup that matches nothing returns no data instead of an error, so check the output before using an ID.

## Change an entity

Writing to an existing entity changes the fields you pass. Fields you leave out keep their values, except that `metadata` is replaced as a whole, so repeat every key you want to keep:

```sh
bao write identity/entity name=bob metadata=team=ops metadata=site=aarhus
bao read -format=json identity/entity/name/bob | jq '.data.metadata'
```

The `site` value is now `aarhus`. If you had written only `metadata=site=aarhus`, the key `team` would be gone.

## Create an alias

An alias connects a login to an entity. It needs three values: a name, the ID of the entity (`canonical_id`), and the accessor of the auth mount. Create one for Bob on the userpass mount:

```sh
BOB_ID=$(bao read -field=id identity/entity/name/bob)
bao write identity/entity-alias name=bob canonical_id=$BOB_ID mount_accessor=$USERPASS_ACCESSOR
bao list identity/entity-alias/id
```

An entity holds at most one alias per auth mount. Aliases are separate objects with their own IDs, so you can read, update and delete one on its own at `identity/entity-alias/id/<alias id>`. When the userpass user `bob` logs in, OpenBao now finds this alias and puts the login under the entity `bob`, instead of creating a new generated entity.

You can also read the entity ID that a token belongs to. Look up your own token and read `entity_id`, which is empty for the root token because it has no login behind it.

```sh
bao token lookup -format=json | jq '.data.entity_id'
```

## Common pitfalls

> [!WARNING]
> - **Dropping metadata keys on update.** Metadata is replaced as a whole. Read the entity first and send every key you want to keep.
> - **Expecting a second write to create a second entity.** The name is unique. A repeated name updates the entity.
> - **Using the auth mount path in an alias.** The alias needs the accessor from `bao auth list`, not `userpass/`.
> - **Treating a failed lookup as an error.** An empty result means no match. Check it before you use the ID.
