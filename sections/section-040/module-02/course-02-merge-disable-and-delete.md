# Merge, Disable And Delete

Entities pile up. People log in through a second method, a person leaves, a test run leaves hundreds of generated entities behind. This part covers the three operations that keep the identity store correct: merging, disabling and deleting.

## Merge entities

**Merging** moves the aliases and group memberships of one or more entities into a target entity, then removes the entities it moved from. Create two entities that should be one person, then merge them:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao write identity/entity name=dana-old metadata=team=ops
bao write identity/entity name=dana-new metadata=site=aarhus
OLD_ID=$(bao read -field=id identity/entity/name/dana-old)
NEW_ID=$(bao read -field=id identity/entity/name/dana-new)
bao write identity/entity/merge from_entity_ids=$OLD_ID to_entity_id=$NEW_ID
bao read identity/entity/name/dana-old
```

The last read finds nothing, because `dana-old` was merged away and deleted. The target keeps its own name and its own metadata. The fields to know are `from_entity_ids` (a list of IDs to merge from), `to_entity_id` (the target), `force` and `conflicting_alias_ids_to_keep`.

## Merge conflicts

Two entities that both have an alias on the same auth mount conflict, because an entity can hold only one alias per mount. The merge stops and names the problem. You then choose which alias survives by passing the alias ID in `conflicting_alias_ids_to_keep`:

```sh
bao write identity/entity/merge from_entity_ids=$OLD_ID to_entity_id=$NEW_ID \
  conflicting_alias_ids_to_keep=<alias id to keep>
```

The alias you do not name is deleted. The `force` option merges without stopping on a conflict. Use it only when you have read both entities and know which alias should win, because it decides for you.

Merging keeps the target's entity ID. Tokens that already belong to a merged-away entity keep working only until they expire or are revoked, because the entity ID they hold no longer exists. For this reason, merge outside of busy hours when many tokens are active, and tell the owners to log in again.

## Disable an entity

A disabled entity cannot be used to log in, and tokens that belong to it stop working. This is the safe first step when a person leaves, because it can be undone:

```sh
bao write identity/entity/name/dana-new disabled=true
bao read -field=disabled identity/entity/name/dana-new
```

Set `disabled=false` to switch it back on. Disabling does not remove the entity's aliases, groups or metadata, so nothing needs to be rebuilt when you re-enable it. Note that it blocks the use of the entity but does not revoke the tokens that exist; revoke those separately with `bao token revoke` if you need them gone at once.

## Delete entities

Deleting removes the entity and all of its aliases. The deletion cannot be undone, and the entity ID is never reused:

```sh
bao delete identity/entity/name/dana-new
```

For many entities, `batch-delete` takes a list of IDs in one call. List the IDs first and check what you are about to remove:

```sh
bao list identity/entity/id
bao write identity/entity/batch-delete entity_ids=<id1>,<id2>
```

A person who logs in again after their entity was deleted gets a new generated entity, because no alias is left. Groups that held the old entity as a member lose it, so policies that came from those groups are gone too.

## Order of operations for a leaver

1. Disable the entity.
2. Revoke the tokens that still exist for the entity.
3. Wait through your retention period, then delete the entity.

## Common pitfalls

> [!WARNING]
> - **Merging without reading the aliases.** A conflict resolved by `force` can delete the alias a person needs to log in.
> - **Deleting instead of disabling.** A delete removes the aliases and group memberships. A disable keeps them.
> - **Expecting a disable to revoke tokens.** The tokens exist until revoked or expired.
> - **Batch-deleting from an unchecked list.** Print the IDs and read them before you send the call.
