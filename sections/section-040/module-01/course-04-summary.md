# Summary

Every successful login maps to an entity through an alias, keyed by the account name and the auth mount's accessor. If no alias exists, OpenBao creates a new entity with a generated name, which is why one person who logs in through two methods can end up as two entities. Creating the entity and its aliases before the first login avoids that; merging entities fixes it afterwards, and keeps the entity's ID, which deleting and recreating would change.

Groups give policies to many entities at once. An internal group lists its members in OpenBao. An external group takes its members from the identity provider: a group alias whose name matches a value in the login's groups claim, on the right mount accessor, adds the entity to the group at login. Group policies are identity policies, shown as `identity_policies` in a token lookup, and OpenBao checks them on every request, so a change in group membership reaches existing tokens at once.

Policy templates put identity values into policy paths, such as `{{identity.entity.name}}`, so one policy gives every person their own folder. They only work for tokens with an entity, and only if the value in the template matches the way the secrets are named.

- One person, one entity: create aliases first or merge later.
- Aliases and group aliases use mount accessors, not mount paths.
- External group alias names must match the claim value exactly.
- `identity_policies` follow group membership without a new login.

<!-- astrona:playground:destroy -->
