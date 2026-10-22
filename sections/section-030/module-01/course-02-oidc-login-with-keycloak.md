# OIDC Login With Keycloak

The company already keeps its people in Keycloak, with their groups. Rather than copy those people into OpenBao, OpenBao can ask Keycloak who is logging in. This part connects OpenBao to Keycloak with OpenID Connect and logs a person in through the browser.

## What OpenBao needs from Keycloak

The **JWT/OIDC auth method** is one plugin with two kinds of role. An **OIDC role** runs a browser login: OpenBao sends the user to Keycloak, Keycloak checks the password and sends the user back with a code, and OpenBao exchanges the code for an ID token. A **JWT role** skips the browser: the client already has an ID token and sends it to OpenBao. Both read the same configuration.

That configuration starts from Keycloak's **discovery document**, a JSON file every OIDC provider publishes at `/.well-known/openid-configuration` under its address. It lists the provider's endpoints and the keys that sign its tokens. OpenBao also needs a **client** in Keycloak: an application registration with an ID and a secret. The playground's Keycloak already has the client `openbao`. Look at the discovery document first:

<!-- astrona:playground:renew -->

```sh
curl -s http://keycloak.localtest.me:8080/realms/inventory/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, jwks_uri}'
```

The `issuer` is `http://keycloak.localtest.me:8080/realms/inventory`. Every token Keycloak signs for this realm carries that value in its `iss` claim, and OpenBao checks it. Because both your browser and OpenBao reach Keycloak by the same name, the issuer matches on both sides.

## Configure the auth method

Enable the auth method at the path `oidc/` and point it at the realm:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable oidc
bao write auth/oidc/config \
  oidc_discovery_url="http://keycloak.localtest.me:8080/realms/inventory" \
  oidc_client_id=openbao oidc_client_secret=openbao-client-secret default_role=person
```

`oidc_discovery_url` is the issuer without the `/.well-known/openid-configuration` part. OpenBao fetches the discovery document when you write the configuration, so a wrong address fails right here, not later at login.

## An OIDC role for the browser

An OIDC role must say where Keycloak may send the user back. These **redirect URIs** must be listed both in the role and in the Keycloak client, or one side refuses the login. The CLI uses a small listener on your machine at `http://localhost:8250/oidc/callback`; the OpenBao web user interface uses `/ui/vault/auth/oidc/oidc/callback` on the OpenBao address. The `vault` in that path is a name OpenBao kept from Vault.

Save this as `role-person.json`:

```json
{
  "role_type": "oidc",
  "user_claim": "preferred_username",
  "groups_claim": "groups",
  "oidc_scopes": ["profile"],
  "allowed_redirect_uris": [
    "http://localhost:8250/oidc/callback",
    "http://openbao.localtest.me:8200/ui/vault/auth/oidc/oidc/callback"
  ],
  "token_policies": ["default"],
  "token_ttl": "1h"
}
```

Write it:

```sh
bao write auth/oidc/role/person @role-person.json
```

`user_claim` picks the claim that names the user, here the Keycloak user name. `groups_claim` picks the claim that lists the user's groups; the playground's Keycloak client puts them in a claim called `groups`.

## Log in through the browser

Now log in as alice. `bao` starts a listener on port 8250, opens Keycloak in your browser, and waits for the redirect:

```sh
(unset BAO_TOKEN; bao login -method=oidc role=person)
```

Sign in to Keycloak as `alice` with the password `alice-password`. The browser shows a short success page, and `bao` prints a token with the policy `default`. The token's metadata shows `role` as `person`. If `bao` cannot open a browser, it prints the URL to open by hand.

You can now connect OpenBao to an identity provider and log a person in through the browser. Every logged-in person gets the same policy so far. The next question is how to give different people different policies, based on what the ID token says about them.

## Common pitfalls

> [!WARNING]
> - **A redirect URI missing on one side.** The role and the Keycloak client must both list it, character for character.
> - **The wrong discovery URL.** Use the issuer of the realm, without `/.well-known/openid-configuration`. A different realm means a different issuer.
> - **Different host names for the browser and for OpenBao.** The issuer depends on the address Keycloak was called with in development mode. If the names differ, the `iss` claim does not match.
> - **Expecting groups without a mapper.** Keycloak adds a `groups` claim only if the client has a group membership mapper.
