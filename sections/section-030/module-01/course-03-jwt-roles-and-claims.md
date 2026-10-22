# JWT Roles, Bound Claims And Login MFA

A browser login proves who someone is, but not that they should get a powerful policy. Only members of the ops team should get `ops`. OpenBao decides that from the claims in the ID token, and a JWT role is the clearest place to see how, because you send the ID token yourself and can read every claim it carries.

## Read the claims in an ID token

A **JWT role** checks an ID token that the client sends directly, with no browser. Automation uses it with tokens it already has, and the labs use it to log people in from a script. To get an ID token without a browser, the playground's Keycloak client allows the password grant. That is a lab shortcut: a real person logs in through the browser.

<!-- astrona:playground:renew -->

```sh
ALICE_ID_TOKEN=$(curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
  -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
  -d username=alice -d password=alice-password -d scope=openid | jq -r .id_token)
jwt_claims() {
  local payload
  payload=$(printf '%s' "$1" | cut -d. -f2 | tr '_-' '/+')
  while [ $(( ${#payload} % 4 )) -ne 0 ]; do payload="$payload="; done
  printf '%s' "$payload" | base64 -d | jq '{iss, aud, preferred_username, groups}'
}
jwt_claims $ALICE_ID_TOKEN
```

A JWT has three parts separated by dots, and the middle one holds the claims, encoded with Base64URL. The helper decodes that part. The claims show the issuer, the audience `openbao` (the client the token was made for), the user name `alice` and the groups `["ops"]`.

## Bind the role to the audience and the group

A JWT role states what an ID token must look like. The most important settings are these:

| Setting | What it checks or does |
| --- | --- |
| `bound_audiences` | The `aud` claim must contain one of these values, so a token made for another application is refused |
| `user_claim` | The claim that names the user; it becomes the name of the user's identity alias |
| `groups_claim` | The claim that lists the user's groups |
| `bound_claims` | Claims that must have one of the listed values, for example the group `ops` |
| `token_policies` | The policies the OpenBao token gets |

Save this as `role-ops.json`:

```json
{
  "role_type": "jwt",
  "bound_audiences": ["openbao"],
  "user_claim": "preferred_username",
  "groups_claim": "groups",
  "bound_claims": {"groups": ["ops"]},
  "token_policies": ["ops"],
  "token_ttl": "1h"
}
```

Write it and log in as alice with her ID token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao write auth/oidc/role/ops @role-ops.json
bao write auth/oidc/login role=ops jwt=$ALICE_ID_TOKEN
```

The login returns a token with `default` and `ops`. Get an ID token for `bob` the same way and log in with the same role: OpenBao refuses it, because bob's `groups` claim is `["dev"]` and the role requires `ops`. That refusal is the point of `bound_claims`: without it, every Keycloak user would get `ops`.

## When a login is refused

OpenBao's error names the check that failed, and the claims tell you why. Compare the two side by side:

| The error is about | Look at |
| --- | --- |
| The audience | The token's `aud` and the role's `bound_audiences` |
| A bound claim | The token's `groups` (or other claim) and the role's `bound_claims` |
| A claim that is missing | `user_claim` or `groups_claim` names a claim the token does not have |
| The issuer or the signature | The `iss` claim and the discovery URL in the configuration |

## Login MFA

For the most sensitive policies, a password, even through Keycloak, may not be enough. **Login MFA** in OpenBao adds a second factor at login: you define an MFA method, for example time-based one-time passwords (TOTP), under `identity/mfa/method/`, and a login enforcement under `identity/mfa/login-enforcement/` that names the auth mounts or groups that must use it. A login through those mounts then waits for the second factor before OpenBao returns a token. Many teams rely on the MFA their identity provider already does, and add OpenBao's login MFA only for local accounts.

You can now read an ID token's claims and write a role that checks its audience and groups, and you know how to find why a login is refused. That is everything the lab needs.

## Common pitfalls

> [!WARNING]
> - **A role without `bound_claims`.** Every user the identity provider knows gets the role's policies.
> - **An empty `bound_audiences`.** A token made for any other application of the same provider is accepted.
> - **The wrong claim name.** `groups_claim=group` when the token has `groups` refuses everyone.
> - **Using the password grant for people.** It is a lab shortcut. People log in through the browser with an OIDC role.

## Your mission: Map A Keycloak Group To An OpenBao Policy

You can now configure the JWT/OIDC auth method and write a role that gives a policy only to one group. The graded lab gives you the auth method enabled but empty, and asks you to configure it from Keycloak and give the policy `ops` to members of the Keycloak group `ops` only.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-113-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-113-lab-030-01
astrona start ats-113-playground-030-01
```
