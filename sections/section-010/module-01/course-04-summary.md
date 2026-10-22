# Summary

Every request to OpenBao carries a token, and every login ends by creating one. A token carries its policies, a time to live, a renewable flag, a type and an accessor, and `bao token lookup` shows all of them. The `default` policy is attached to every token unless you ask for it not to be. The accessor identifies a token without being usable, so it is the safe thing to log and to use for administration.

A token's TTL counts down from its creation or last renewal. Renewal resets it, but never past the max TTL of the system, the mount or the role, and never past an explicit max TTL on the token itself. A periodic token is different: every renewal resets it to its period, with no upper limit, so a service that renews within each period keeps its token for as long as it runs.

OpenBao has service tokens, which are stored, renewable and revocable one by one, and batch tokens, which are cheap encrypted blobs that cannot be renewed and expire on their own. Service tokens form a tree: revoking a token revokes all its children. Orphan tokens have no parent, so they survive. Token roles store the settings of the tokens a service may create, and their `allowed_policies` is the real limit on what those tokens can do.

- `bao token lookup` and `bao token lookup -accessor` show a token's settings.
- A periodic token suits a service that renews; a person should log in again.
- Create service tokens as orphans so they do not die with an administrator's session.
- A token role's `allowed_policies` decides how much power its tokens can have.

<!-- astrona:playground:destroy -->
