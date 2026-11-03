# Summary

Entities are managed by name and by ID. A write with an existing name updates the entity, and metadata is replaced as a whole. Aliases connect a login to an entity and are keyed by name and mount accessor, one per mount. Lookups find an entity from a name or an alias and return nothing instead of an error when there is no match.

Merging moves aliases and group memberships into a target entity and keeps the target's ID. Alias conflicts stop the merge until you choose an alias to keep. Disabling an entity blocks its use and keeps its data, so it is the safe first step for a leaver. Deleting removes the aliases and group memberships for good, and a later login creates a new entity.

An identity token is a signed JWT built from the entity of the calling token. A named key signs it, with an algorithm, a rotation period and a verification period. A role sets the lifetime and the claims template, and OpenBao adds `iss`, `sub`, `aud`, `iat` and `exp`. The token is read at `identity/oidc/token/<role>` with a token that has an entity and a policy for that path.

Receivers verify tokens with the public keys at the `.well-known` paths, check the issuer, the audience and the expiry, and may ask OpenBao to introspect a token. Rotation signs new tokens with a new key and keeps the old public key for the verification period, which must be longer than the longest token lifetime.

- Create entities and aliases before the first login, merge later if needed.
- Disable first, revoke tokens, delete last.
- Claims come from entity metadata, so the metadata must be set before the token is read.
- Keep the verification period longer than the longest role `ttl`.

<!-- astrona:playground:destroy -->
