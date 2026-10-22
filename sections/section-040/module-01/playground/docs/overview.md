# Overview: Join Logins Into One Identity (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with OpenBao initialized and unsealed, userpass and JWT login configured, and Keycloak, and then waits. No entities exist yet. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

- **OpenBao v2.7.1** in the namespace `openbao`, initialized and unsealed, with the lab-only root token in the Secret `openbao-init`.
- The auth method `userpass/` with the user `alice` (password `alice-password`).
- The auth method `oidc/` configured for the Keycloak realm `inventory`, with the JWT role `person` (`user_claim` `preferred_username`, `groups_claim` `groups`, policy `default`).
- **Keycloak 26.8.1** with `alice` (group `ops`) and `bob` (group `dev`), passwords `alice-password` and `bob-password` (lab-only).
- The policies `ops` and `ops-shared`, and a KV engine at `secret/` with `secret/users/alice/note` and `secret/users/bob/note`.

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

Paste these once in each new terminal. `entity_of_userpass` and `entity_of_jwt` log a person in and print the entity ID of the login. `mount_accessor` prints the accessor of an auth mount.

```sh
entity_of_userpass() {
  bao write -format=json "auth/userpass/login/$1" password="$1-password" | jq -r .auth.entity_id
}
entity_of_jwt() {
  local id_token
  id_token=$(curl -s -X POST http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | jq -r .id_token)
  bao write -format=json auth/oidc/login role=person jwt="$id_token" | jq -r .auth.entity_id
}
mount_accessor() {
  bao auth list -format=json | jq -r --arg mount "$1/" '.[$mount].accessor'
}
```

Use them like this: `entity_of_userpass alice`, `entity_of_jwt alice`, `mount_accessor oidc`.

## Practice tasks

- Log alice in both ways before you create anything, and list the entities. Then merge them into one entity named `alice`.
- Create an entity `bob`, give it only an alias on `oidc/`, and log bob in through JWT. Check which entity he lands on.
- Put alice in an internal group, log in once, then remove her from the group and look up the same token again.
- Create an external group with a group alias named `Ops` (capital O), log alice in with JWT and check whether she joined. Fix the name.
- Write a policy template on `{{identity.entity.metadata.team}}` and give alice the metadata `team=ops`.
