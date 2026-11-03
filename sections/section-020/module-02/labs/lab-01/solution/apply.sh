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
bao_root write auth/approle/role/deploy token_policies=ci-deploy token_ttl=10m token_max_ttl=20m \
  secret_id_ttl=15m secret_id_num_uses=1
bao_root policy write deploy-orchestrator - <<'HCL'
path "auth/approle/role/deploy/role-id" {
  capabilities = ["read"]
}
path "auth/approle/role/deploy/secret-id" {
  capabilities = ["update"]
}
HCL
ORCHESTRATOR_TOKEN="$(bao_root token create -policy=deploy-orchestrator -ttl=1h -field=token)"
WRAPPED="$(kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN="$ORCHESTRATOR_TOKEN" \
  bao write -wrap-ttl=2h -f -field=wrapping_token auth/approle/role/deploy/secret-id)"
kubectl -n clients delete secret deploy-wrapped-secret-id --ignore-not-found
kubectl -n clients create secret generic deploy-wrapped-secret-id --from-literal=token="$WRAPPED"
