# Verify And Rotate

A token is only useful if the receiver can check it. This part shows what the receiver needs from OpenBao, how to ask OpenBao to check a token itself, and how key rotation keeps old tokens valid for a planned time.

## The discovery document and the public keys

OpenBao publishes two documents about its identity tokens. Neither needs authentication, because the receiver has no OpenBao token:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
curl -s $BAO_ADDR/v1/identity/oidc/.well-known/openid-configuration | jq
curl -s $BAO_ADDR/v1/identity/oidc/.well-known/keys | jq
```

The discovery document names the `issuer` and the address of the key set (`jwks_uri`). The key set lists the public keys in JSON Web Key format, each with a `kid`. The `kid` also appears in the JWT header, so the receiver knows which key to use. A receiver checks four things: the signature against the key with that `kid`, that `iss` equals the expected issuer, that `aud` equals its own client ID, and that the current time is before `exp`.

## Set the issuer

The `iss` claim comes from the issuer setting. If you never set it, OpenBao builds it from its configured API address, which may not be an address the receiver can reach. Set it to the address that receivers use:

```sh
bao write identity/oidc/config issuer=http://openbao.localtest.me:8200
bao read identity/oidc/config
```

The issuer must match exactly between the token, the discovery document and the receiver's configuration. A change in the issuer makes every receiver reject tokens until it is updated too.

## Introspect a token

OpenBao can answer whether a token is currently valid. This checks the signature, the expiry and that the entity still exists:

```sh
ALICE_TOKEN=$(bao write -field=token auth/userpass/login/alice password=alice-password)
JWT=$(BAO_TOKEN=$ALICE_TOKEN bao read -field=token identity/oidc/token/inventory-reader)
bao write -format=json identity/oidc/introspect token=$JWT | jq
```

The answer has `active` set to `true` for a valid token. A tampered, expired or unknown token returns `active` as `false`. Introspection needs a call to OpenBao, so use the public keys for normal checks and introspection when you must be sure the entity is still there.

## Rotate a key

Rotation makes OpenBao sign new tokens with a new key. It runs by itself every `rotation_period`. Run it by hand when a key may have leaked, or to see the effect:

```sh
bao read -format=json identity/oidc/.well-known/keys | jq '.keys | length'
bao write -f identity/oidc/key/inventory/rotate
curl -s $BAO_ADDR/v1/identity/oidc/.well-known/keys | jq '.keys | length'
```

The key set now holds the new public key and the previous one. The previous key stays published for `verification_ttl`, so tokens that were signed with it before the rotation still verify until they expire. After that time, OpenBao removes it from the set. You can pass a `verification_ttl` on the rotate call to change the overlap for this rotation only:

```sh
bao write identity/oidc/key/inventory/rotate verification_ttl=1h
```

Choose the two times together. The verification period must be at least as long as the longest role `ttl` plus the time receivers cache the key set. Otherwise a token that is still within its lifetime fails verification after a rotation.

## Common errors

| Symptom | Likely cause |
| --- | --- |
| `permission denied` on `identity/oidc/token/<role>` | The token's policies do not allow `read` on that path |
| An error that the token has no entity | The call used the root token or a token without a login behind it |
| Receiver rejects `iss` | The issuer is not set, or differs from the receiver's configuration |
| Receiver rejects `aud` | The receiver expects another client ID than the role's |
| Verification fails right after rotation | The receiver cached the key set, or the verification period is too short |

## Common pitfalls

> [!WARNING]
> - **Rotating with a short verification period.** Live tokens stop verifying. Keep the period longer than the longest token lifetime.
> - **Changing the issuer without updating receivers.** Every token is rejected until they match.
> - **Caching the key set forever.** Receivers must reload it when they see an unknown `kid`.
> - **Using introspection for every request.** It adds a call to OpenBao to each check. Use the public keys for normal checks.
