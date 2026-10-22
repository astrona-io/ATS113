#!/usr/bin/env bash
# Reference solution, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this. Taken from solution.md - if one changes, change the other.
set -uo pipefail

ROOT_TOKEN="$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)"
# bao_root runs the bao CLI inside the OpenBao pod with the lab-only root token.
bao_root() { kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$ROOT_TOKEN" bao "$@"; }
# in_tester runs a command in the tester pod (namespace clients).
in_tester() { kubectl -n clients exec -i deploy/tester -- "$@"; }
# json_field reads one jq expression from JSON on stdin, using jq in the tester pod.
json_field() { kubectl -n clients exec -i deploy/tester -- jq -r "$1"; }
# login_post PATH JSON: POST a login request from the tester pod, print the response.
login_post() {
  printf '%s' "$2" | in_tester curl -s -X POST -H 'Content-Type: application/json' \
    --data-binary @- "http://openbao.localtest.me:8200/v1/$1"
}
# lookup_self TOKEN: the token's own lookup, from the tester pod.
lookup_self() {
  in_tester curl -s -H "X-Vault-Token: $1" http://openbao.localtest.me:8200/v1/auth/token/lookup-self
}
# keycloak_id_token USER: an ID token for a lab user from Keycloak's password
# grant (a lab shortcut; people log in through the browser).
keycloak_id_token() {
  in_tester curl -s -X POST \
    http://keycloak.localtest.me:8080/realms/inventory/protocol/openid-connect/token \
    -d grant_type=password -d client_id=openbao -d client_secret=openbao-client-secret \
    -d username="$1" -d password="$1-password" -d scope=openid | json_field '.id_token // empty'
}

set -e
ENTITY_ID="$(kubectl -n clients get configmap capstone-baseline -o jsonpath='{.data.alice-entity-id}')"
OIDC_ACCESSOR="$(bao_root auth list -format=json | json_field '."oidc/".accessor')"
# Find the entity that holds alice's oidc alias and merge it into alice.
DUPLICATE="$(bao_root write -format=json identity/lookup/entity alias_name=alice alias_mount_accessor="$OIDC_ACCESSOR" | json_field '.data.id // empty')"
if [ -n "$DUPLICATE" ] && [ "$DUPLICATE" != "$ENTITY_ID" ]; then
  bao_root write identity/entity/merge from_entity_ids="$DUPLICATE" to_entity_id="$ENTITY_ID" >/dev/null
fi
GROUP_ID="$(bao_root read -field=id identity/group/name/ops-external)"
ALIAS_ID="$(bao_root read -format=json identity/group/name/ops-external | json_field '.data.alias.id // empty')"
[ -n "$ALIAS_ID" ] && bao_root delete "identity/group-alias/id/$ALIAS_ID" >/dev/null
bao_root write identity/group-alias name=ops mount_accessor="$OIDC_ACCESSOR" canonical_id="$GROUP_ID" >/dev/null
bao_root policy write personal - >/dev/null <<'HCL'
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update"]
}
HCL
