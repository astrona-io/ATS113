# Overview: Log People In With Userpass And Keycloak (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed and Keycloak with a realm, users and a client, and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- **OpenBao v2.7.1** in the namespace `openbao`, initialized and unsealed, with the lab-only root token in the Secret `openbao-init`. No auth method except tokens is enabled yet.
- The policies `ops`, `dev` and `breakglass`, and a KV engine at `secret/` with `secret/ops/runbook`.
- **Keycloak 26.8.1** in the namespace `keycloak`, at `http://keycloak.localtest.me:8080`. Administrator `admin` / `admin` (lab-only).
- The realm `inventory` with `alice` (group `ops`, password `alice-password`) and `bob` (group `dev`, password `bob-password`), and the confidential client `openbao` (secret `openbao-client-secret`) with a `groups` claim and the redirect URIs for the CLI and the web user interface.

Start the port-forwards in a second terminal, then set the address and the lab-only root token:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200 &
kubectl -n keycloak port-forward svc/keycloak 8080:8080 &
```

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `keycloak_id_token` gets an ID token for a lab user with the password grant, a lab shortcut. `jwt_claims` prints the claims of a token that matter for OpenBao roles.

```sh
keycloak_id_token() {
  curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | jq -r .id_token
}
jwt_claims() {
  local payload
  payload=$(printf '%s' "$1" | cut -d. -f2 | tr '_-' '/+')
  while [ $(( ${#payload} % 4 )) -ne 0 ]; do payload="$payload="; done
  printf '%s' "$payload" | base64 -d | jq '{iss, aud, preferred_username, groups}'
}
```

Use them like this: `jwt_claims $(keycloak_id_token bob)`.

## Practice tasks

- Open the Keycloak administration console at `http://keycloak.localtest.me:8080/admin`, find the client `openbao` and its group mapper, and switch "Full group path" on. Get a new ID token and compare its `groups` claim. Switch it back.
- Write a JWT role with `bound_audiences` set to `account` and try alice's ID token. Read the error.
- Log in through the OpenBao web user interface at `http://openbao.localtest.me:8200/ui/` with the OIDC role `person`.
- Add bob to the group `ops` in Keycloak, get a new ID token, and log in with the role `ops`. Remove him again.
- Create a userpass user, log in, change the user's password, and check that the old token still works.
