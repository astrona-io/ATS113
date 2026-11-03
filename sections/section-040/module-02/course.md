# Entity Operations And Identity Tokens

Every login in OpenBao points at an entity, and the entity is more than a name. It holds metadata, aliases and group memberships, and OpenBao can turn those facts into a signed token that other systems verify without calling OpenBao for every request. This module covers the day-to-day entity operations and then the identity token, which is a JSON Web Token (JWT) built from an entity.

The module has four parts. **Entity Operations** creates, reads, lists and changes entities and aliases. **Merge, Disable And Delete** moves aliases between entities, switches an entity off, and removes entities safely. **Issue Identity Tokens** creates a signing key and a role with a claims template, and reads a token as a logged-in entity; a graded lab follows it. **Verify And Rotate** shows how a receiver checks the token with the public keys, and how to rotate the key without breaking tokens that are still valid.

## Learning objectives

After this module you can:

- Create an entity by name with metadata and policies, and look it up by name or by alias.
- Create an alias for a login on an auth mount, using the mount accessor.
- Merge entities, disable an entity, and delete entities in bulk.
- Create an identity token key with an algorithm, a rotation period and a verification period.
- Create a role with a claims template that uses entity values.
- Read an identity token and decode its claims.
- Publish and read the discovery document and the public keys, and introspect a token.
- Rotate a key and explain how long old tokens stay verifiable.

## Before you start

You should know what an entity and an alias are, and how to log in with the userpass method. The module on entities and aliases in this section covers both.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1**, initialized and unsealed. It holds:

| Object | What it is |
| --- | --- |
| Userpass user `alice` | Password `alice-password` (lab-only), with the policy `identity-reader` |
| Entity `alice` | Created for you, with an alias for the userpass login `alice` and no metadata |
| Policy `identity-reader` | Lets a token read `identity/oidc/token/*` |
| KV engine `secret/` | Example secrets, as in the other modules |

Start a port-forward in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
