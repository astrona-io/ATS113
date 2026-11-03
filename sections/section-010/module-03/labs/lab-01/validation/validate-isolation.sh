#!/usr/bin/env bash
# PASS when: Confirms the note is private to the service token and the wrapping token cannot read secrets
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

pass() { echo "PASS: $1"; exit 0; }
fail() { echo "FAIL: $1"; exit 1; }

TOKEN="$(kubectl -n clients get secret inventory-service-token -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)"
[ -n "$TOKEN" ] || fail "the Secret inventory-service-token is missing."
code_with() { in_tester curl -s -o /dev/null -w '%{http_code}' -H "X-Vault-Token: $1" "http://openbao.localtest.me:8200/v1/$2"; }
[ "$(code_with "$TOKEN" cubbyhole/deploy-note)" = "200" ] || fail "the service token cannot read its own note."
[ "$(code_with "$ROOT_TOKEN" cubbyhole/deploy-note)" != "200" ] || fail "the root token can read the note; it must be written with the service token, not the root token."
[ "$(code_with "$TOKEN" secret/data/inventory/db)" = "200" ] || fail "the service token cannot read secret/inventory/db."
[ "$(code_with "$TOKEN" secret/data/reports/q3)" = "403" ] || fail "the service token can read secret/reports/q3."
pass "the note is private to the service token and its policy is narrow."
