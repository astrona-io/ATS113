# Solution: Repair A Broken Keycloak Login

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

## Step 1: Connect and reproduce

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
id_token_for() {
  curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | jq -r .id_token
}
bao write auth/oidc/login role=ops jwt=$(id_token_for alice)
```

The login is refused. Fix one thing at a time and run this login after each fix; the error changes as each fault goes away.

## Step 2: The discovery URL

```sh
bao read auth/oidc/config
```

`oidc_discovery_url` points at the realm `master`, but alice's tokens come from the realm `inventory`, so the issuer and the signing keys do not match.

```sh
bao write auth/oidc/config \
  oidc_discovery_url="http://keycloak.localtest.me:8080/realms/inventory" \
  oidc_client_id=openbao oidc_client_secret=openbao-client-secret
```

## Step 3: The role

Decode alice's token and read the role side by side:

```sh
jwt_claims() {
  local payload
  payload=$(printf '%s' "$1" | cut -d. -f2 | tr '_-' '/+')
  while [ $(( ${#payload} % 4 )) -ne 0 ]; do payload="$payload="; done
  printf '%s' "$payload" | base64 -d | jq '{iss, aud, preferred_username, groups}'
}
jwt_claims $(id_token_for alice)
bao read auth/oidc/role/ops
```

The token's `aud` is `openbao`, but the role's `bound_audiences` is `account`. The token's groups are in `groups`, but the role's `groups_claim` is `group`. Save this as `role-ops.json`:

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

Write it and log in again:

```sh
bao write auth/oidc/role/ops @role-ops.json
bao write auth/oidc/login role=ops jwt=$(id_token_for alice)
bao write auth/oidc/login role=ops jwt=$(id_token_for bob)
```

alice gets `ops`; bob is still refused.

## Step 4: The break-glass account

Change only the account's policies, so its password stays:

```sh
bao write auth/userpass/users/breakglass/policies token_policies=breakglass
bao write auth/userpass/login/breakglass password=breakglass-password
```

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Empty `bound_audiences` | The role accepts tokens for any client; the grader requires `openbao` |
| Remove `bound_claims` | bob gets `ops` |
| Create a new userpass user with the policy | The task needs the existing account `breakglass` to work; a second account is one more password to protect |
