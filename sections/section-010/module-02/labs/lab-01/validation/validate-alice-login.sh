#!/usr/bin/env bash
# PASS when: Confirms alice logs in at staff with inventory-read and a 30 minute token
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

RESP="$(login_post auth/staff/login/alice '{"password":"alice-password"}')"
printf '%s' "$RESP" | json_field '.auth.client_token // empty' | grep -q . || fail "alice cannot log in at auth/staff with the password alice-password."
printf '%s' "$RESP" | in_tester jq -e '.auth.policies | index("inventory-read")' >/dev/null || fail "the token of alice does not carry inventory-read."
printf '%s' "$RESP" | in_tester jq -e '.auth.policies | index("root") | not' >/dev/null || fail "the token of alice carries root."
[ "$(printf '%s' "$RESP" | json_field '.auth.lease_duration')" = "1800" ] || fail "the token of alice does not start with a 30 minute lease."
pass "alice logs in with inventory-read and a 30 minute lease."
