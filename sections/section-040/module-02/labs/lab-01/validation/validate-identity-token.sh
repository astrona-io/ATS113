#!/usr/bin/env bash
# PASS when: Confirms alice logs in, reads an identity token with the right claims, and introspection accepts it
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

LOGIN="$(login_post auth/userpass/login/alice '{"password":"alice-password"}')"
ATOKEN="$(printf '%s' "$LOGIN" | json_field '.auth.client_token // empty')"
[ -n "$ATOKEN" ] || fail "alice cannot log in with userpass."
RESP="$(in_tester curl -s -H "X-Vault-Token: $ATOKEN" http://openbao.localtest.me:8200/v1/identity/oidc/token/inventory-reader)"
JWT="$(printf '%s' "$RESP" | json_field '.data.token // empty')"
[ -n "$JWT" ] || fail "alice cannot read a token from identity/oidc/token/inventory-reader."
CLIENT="$(printf '%s' "$RESP" | json_field '.data.client_id')"
CLAIMS="$(printf '%s' "$JWT" | in_tester jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson')"
[ "$(printf '%s' "$CLAIMS" | json_field '.team')" = "inventory" ] || fail "the claim team is not inventory."
[ "$(printf '%s' "$CLAIMS" | json_field '.name')" = "alice" ] || fail "the claim name is not alice."
[ "$(printf '%s' "$CLAIMS" | json_field '.aud')" = "$CLIENT" ] || fail "the audience is not the role client_id."
[ "$(printf '%s' "$CLAIMS" | json_field '.exp - .iat')" = "1800" ] || fail "the token lifetime is not 30 minutes."
EID="$(bao_root read -field=id identity/entity/name/alice)"
[ "$(printf '%s' "$CLAIMS" | json_field '.sub')" = "$EID" ] || fail "the subject is not the entity ID of alice."
ACTIVE="$(printf '{"token":"%s"}' "$JWT" | in_tester curl -s -X POST -H "X-Vault-Token: $ATOKEN" --data-binary @- http://openbao.localtest.me:8200/v1/identity/oidc/introspect | json_field '.active')"
[ "$ACTIVE" = "true" ] || fail "introspection does not report the token as active."
pass "alice reads a valid identity token with the claims team=inventory and name=alice."
