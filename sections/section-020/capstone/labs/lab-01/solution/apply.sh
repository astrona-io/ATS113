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
bao_root write auth/kubernetes/role/inventory \
  bound_service_account_names=inventory bound_service_account_namespaces=inventory \
  token_policies=inventory-app token_ttl=1h >/dev/null
bao_root write auth/approle/role/ci token_policies=ci-deploy token_ttl=20m \
  secret_id_ttl=24h secret_id_bound_cidrs="" >/dev/null
ROLE_ID="$(bao_root read -field=role_id auth/approle/role/ci/role-id)"
SECRET_ID="$(bao_root write -f -field=secret_id auth/approle/role/ci/secret-id)"
kubectl -n clients delete secret ci-approle --ignore-not-found
kubectl -n clients create secret generic ci-approle \
  --from-literal=role_id="$ROLE_ID" --from-literal=secret_id="$SECRET_ID"
bao_root write auth/cert/certs/reporting allowed_common_names=reporting-job >/dev/null
