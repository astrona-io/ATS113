# Identity In Policy Templates

Every engineer should have a private folder of secrets that only they can read. With plain policies, that means one policy per person, written by hand and kept in step with the staff list. A policy template writes the person's name into the path at request time, so one policy serves everyone.

## How a template works

A **policy template** is a policy whose paths contain placeholders in double braces, such as `{{identity.entity.name}}`. When a token makes a request, OpenBao fills each placeholder with a value from the token's entity and groups, and then checks the path as usual. If a placeholder has no value, for example because the token has no entity, the path matches nothing.

| Placeholder | Filled with |
| --- | --- |
| `{{identity.entity.id}}` | The entity's ID |
| `{{identity.entity.name}}` | The entity's name |
| `{{identity.entity.metadata.<key>}}` | One metadata value of the entity |
| `{{identity.entity.aliases.<mount accessor>.name}}` | The entity's alias name on one auth mount |
| `{{identity.groups.names.<group name>.id}}` | The ID of a group the entity is in |

The playground keeps a note for each person under `secret/users/<name>/`. A template on the entity's name gives each person their own folder.

## Write the template

<!-- astrona:playground:renew -->

Save this as `policy-personal.hcl`:

```hcl
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update"]
}
```

Write it and give it to alice's userpass account:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao policy write personal policy-personal.hcl
bao write auth/userpass/users/alice/policies token_policies=personal
```

The template only works for a token whose entity is named `alice`. If alice's userpass login still has a generated entity name, such as `entity-...`, link it to an entity named `alice` first; the entity name, not the user name, fills the placeholder.

## Prove it with two paths

Log in as alice and try her folder and bob's:

```sh
ALICE_TOKEN=$(bao write -field=token auth/userpass/login/alice password=alice-password)
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/users/alice/note
BAO_TOKEN=$ALICE_TOKEN bao kv put secret/users/alice/todo text="rotate the runbook"
BAO_TOKEN=$ALICE_TOKEN bao kv get secret/users/bob/note
```

alice reads and writes under `secret/users/alice/`, and is refused `secret/users/bob/note`. The same policy, given to bob, would give him `secret/users/bob/` and nothing of alice's. Using the entity name ties the folder to the person, not to one of their accounts: alice gets the same folder whether she logs in with userpass or through Keycloak, because both logins land on the same entity.

## Name or ID

`{{identity.entity.name}}` is easy to read in paths, but a name can be changed. `{{identity.entity.id}}` never changes, but paths become long random strings. Pick one and use it everywhere: a template on the ID and secrets stored under names will never match.

You now know how to write one policy that gives every person their own space, and why that depends on each person having exactly one entity with the right name.

## Common pitfalls

> [!WARNING]
> - **A template for tokens without an entity.** A root token or a token created directly has no entity, so the placeholders are empty and the path matches nothing.
> - **Mixing name and ID.** A template on `{{identity.entity.id}}` does not match folders named after people.
> - **Duplicate entities.** If a person has two entities with different names, each login sees a different folder. Merge them.
> - **Writing `secret/users/...` instead of `secret/data/users/...`.** KV version 2 stores data under `data/`.
