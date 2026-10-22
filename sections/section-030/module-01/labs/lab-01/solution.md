# Solution: Map A Keycloak Group To An OpenBao Policy

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect to OpenBao and Keycloak

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
curl -s http://keycloak.localtest.me:8080/realms/inventory/.well-known/openid-configuration | jq -r .issuer
```

The issuer is `http://keycloak.localtest.me:8080/realms/inventory`; that is the discovery URL.

## Step 2: Configure the auth method

```sh
bao write auth/oidc/config \
  oidc_discovery_url="http://keycloak.localtest.me:8080/realms/inventory" \
  oidc_client_id=openbao oidc_client_secret=openbao-client-secret
```

OpenBao fetches the discovery document while it saves the configuration, so a typo fails here.

## Step 3: Write the role

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

Write it:

```sh
bao write auth/oidc/role/ops @role-ops.json
```

## Step 4: Prove both sides

Get ID tokens with the lab-only password grant and log in with each:

```sh
id_token_for() {
  curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | jq -r .id_token
}
bao write auth/oidc/login role=ops jwt=$(id_token_for alice)
bao write auth/oidc/login role=ops jwt=$(id_token_for bob)
```

alice gets a token with `ops`; bob is refused, because his `groups` claim does not contain `ops`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Leave out `bound_claims` | bob gets `ops`, and the grader rejects it |
| Leave out `bound_audiences` | The role accepts tokens made for any client of the realm |
| `role_type=oidc` | An OIDC role does not accept a token sent with `jwt=`; the grader's login fails |
